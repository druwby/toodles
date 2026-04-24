// MatchmakingService.swift
// Toodles
// TDV-82: Live matchmaking via Firestore queue (Subproject C of v1.1 roadmap)
// Supersedes the demo-only pairing in StartChattingView.DemoPeerPool.
//
// Design summary (see docs/superpowers/specs/2026-04-22-toodles-v1.1-roadmap-design.md):
//
//   - Queue doc:   matchmaking_queue/{uid} — rich profile snapshot +
//                   status (waiting|matched|cancelled) + heartbeat
//   - Session doc: sessions/{sessionID} — participants, mode, status
//   - Pairing:     client scans for compatible waiting peers, scores them
//                   with MatchScorer, attempts a Firestore transaction
//                   that flips both queue entries to "matched" and writes
//                   the session doc atomically. The transaction is the
//                   race-condition guard.
//   - Fallback:    after 15s of no match, the caller is expected to hand
//                   off to DemoPeerPool so single-user testing still works.
//
// DEMO_MODE stays on because the Daily SDK can't be linked without Daily.co
// credentials wired at build time. Real matching happens either way; only
// the video rendering differs (mock vs. Daily).

import Foundation
import FirebaseFirestore
import Combine

enum MatchmakingStatus: Equatable {
    case idle
    case searching
    case matched(session: MatchSession)
    case timedOut
    case failed(String)

    static func == (lhs: MatchmakingStatus, rhs: MatchmakingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.searching, .searching), (.timedOut, .timedOut):
            return true
        case (.matched(let l), .matched(let r)):
            return l.sessionID == r.sessionID
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

/// Shape the caller needs to render a call view once paired. Minimal by
/// design — full peer profile is loaded separately by UserViewModel if the
/// caller wants more.
struct MatchSession: Equatable {
    let sessionID: String
    let partnerUID: String
    let partnerName: String
    let partnerPhotoUrl: String?
    let partnerSubtitle: String?
    let sharedInterests: [String]
    /// "mock" for Appetize/DEMO_MODE builds; "daily" when the Daily.co
    /// integration is wired. Determines which call view the caller opens.
    let mode: String
}

@MainActor
final class MatchmakingService: ObservableObject {

    // MARK: - Config

    /// How long the service scans for a real peer before giving up and
    /// allowing the caller to fall back to the demo pool. 15s keeps the
    /// UI responsive — on Appetize anything longer feels broken.
    static let scanTimeoutSeconds: TimeInterval = 15

    /// Heartbeat interval. Queue entries whose lastHeartbeat is older
    /// than 3x this are treated as stale and ignored during matching.
    static let heartbeatIntervalSeconds: TimeInterval = 10
    static var staleEntryThresholdSeconds: TimeInterval { heartbeatIntervalSeconds * 3 }

    // MARK: - Published state

    @Published private(set) var status: MatchmakingStatus = .idle
    @Published private(set) var isSearching: Bool = false

    // MARK: - Private state

    private let db = Firestore.firestore()
    private let queueCollection = "matchmaking_queue"
    private let sessionsCollection = "sessions"

    // AuthManager (REST-API based) is the source of truth for the current
    // UID — we don't use FirebaseAuth SDK because Appetize.io blocks its
    // Keychain dependency. See App/AuthManager.swift.
    private var currentUID: String? { AuthManager.shared.currentUID }
    private var heartbeatTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?
    private var queueListener: ListenerRegistration?

    // Tear down the Firestore listener and in-flight tasks if SwiftUI drops
    // the @StateObject mid-search (user backgrounds the app, navigates away
    // without hitting Cancel). Without this, queueListener stays attached
    // until Firestore's own timeout and the queue entry stays `waiting`
    // until the 30-second heartbeat cutoff reaps it on the next scan.
    deinit {
        queueListener?.remove()
        heartbeatTask?.cancel()
        scanTask?.cancel()
    }

    // MARK: - Public API

    /// Enter the queue and start scanning. The caller should observe `status`
    /// for transitions and navigate to the call view on `.matched`.
    func startSearching(as me: User) async {
        guard let uid = currentUID else {
            status = .failed("Not signed in.")
            return
        }
        // Reset from any prior session before we re-enter.
        await cancelSearch()

        status = .searching
        isSearching = true

        do {
            try await writeQueueEntry(uid: uid, user: me, status: "waiting", sessionID: nil)
        } catch {
            status = .failed("Couldn't join the queue: \(error.localizedDescription)")
            isSearching = false
            return
        }

        startHeartbeat(uid: uid, user: me)
        startQueueListener(uid: uid)
        startScan(me: me, uid: uid)
    }

    /// Cancel an in-flight search. Safe to call from any state.
    func cancelSearch() async {
        heartbeatTask?.cancel(); heartbeatTask = nil
        scanTask?.cancel(); scanTask = nil
        queueListener?.remove(); queueListener = nil

        if let uid = currentUID {
            // Mark our entry cancelled rather than deleting — the partner's
            // transaction may still read it. Cleanup runs server-side or
            // on the next entry.
            try? await db.collection(queueCollection).document(uid).setData([
                "status": "cancelled",
                "lastHeartbeat": FieldValue.serverTimestamp()
            ], merge: true)
        }

        isSearching = false
        if case .searching = status { status = .idle }
    }

    // MARK: - Queue entry

    private func writeQueueEntry(
        uid: String,
        user: User,
        status: String,
        sessionID: String?
    ) async throws {
        var data: [String: Any] = [
            "uid": uid,
            "status": status,
            "displayName": user.displayName,
            "interests": user.interests,
            "trustScore": user.trustScore,
            "accountAgeDays": user.accountAgeDays,
            "photoUrl": user.profilePhotoUrl ?? "",
            "gender": user.gender?.rawValue ?? "",
            "showMe": user.showMe?.rawValue ?? ShowMe.everyone.rawValue,
            "joinedAt": FieldValue.serverTimestamp(),
            "lastHeartbeat": FieldValue.serverTimestamp()
        ]
        if let sid = sessionID { data["sessionID"] = sid }
        try await db.collection(queueCollection).document(uid).setData(data, merge: true)
    }

    // MARK: - Heartbeat

    private func startHeartbeat(uid: String, user: User) {
        heartbeatTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Self.heartbeatIntervalSeconds * 1_000_000_000))
                if Task.isCancelled { return }
                try? await self.db.collection(self.queueCollection).document(uid).updateData([
                    "lastHeartbeat": FieldValue.serverTimestamp()
                ])
            }
        }
    }

    // MARK: - Queue listener
    //
    // Our own queue entry transitions to "matched" when a *peer* pairs with us.
    // The listener picks that up and transitions us into the session.

    private func startQueueListener(uid: String) {
        queueListener = db.collection(queueCollection).document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self,
                      let data = snap?.data(),
                      let status = data["status"] as? String,
                      status == "matched",
                      let sid = data["sessionID"] as? String
                else { return }
                Task { @MainActor in
                    await self.enterSession(sid: sid, uid: uid)
                }
            }
    }

    // MARK: - Scan

    private func startScan(me: User, uid: String) {
        scanTask = Task { [weak self] in
            guard let self = self else { return }
            let deadline = Date().addingTimeInterval(Self.scanTimeoutSeconds)
            while !Task.isCancelled, Date() < deadline {
                if await self.tryPairOnce(me: me, myUID: uid) {
                    return // status will transition via listener or enterSession
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // poll every 2s
            }
            if Task.isCancelled { return }

            // Timeout — status stays `.searching` long enough for the UI to
            // notice and hand off to the demo pool, then resets.
            await MainActor.run {
                self.status = .timedOut
                self.isSearching = false
            }
        }
    }

    /// Attempts to pair with the best available candidate. Returns true when
    /// a pairing transaction succeeded (status transitions via listener).
    private func tryPairOnce(me: User, myUID: String) async -> Bool {
        let candidates = await fetchCompatibleCandidates(me: me, myUID: myUID)
        guard !candidates.isEmpty else { return false }

        // Score and sort. Highest score first; tiebreaker = earliest joinedAt.
        let ranked = candidates
            .map { ($0, MatchScorer.score(current: me, candidate: $0.candidate).total) }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.joinedAt < rhs.0.joinedAt
            }

        for (entry, _) in ranked.prefix(3) {
            if await attemptTransaction(me: me, myUID: myUID, peer: entry) {
                return true
            }
        }
        return false
    }

    /// Pulls waiting queue entries and filters those mutually compatible
    /// with `me` (showMe preferences on both sides + staleness filter).
    private func fetchCompatibleCandidates(me: User, myUID: String) async -> [QueueEntry] {
        do {
            let snap = try await db.collection(queueCollection)
                .whereField("status", isEqualTo: "waiting")
                .limit(to: 30)
                .getDocuments()
            let cutoff = Date().addingTimeInterval(-Self.staleEntryThresholdSeconds)
            let myShowMe = me.showMe ?? .everyone
            let myGender = me.gender

            return snap.documents.compactMap { doc -> QueueEntry? in
                let data = doc.data()
                let uid = doc.documentID
                guard uid != myUID else { return nil }

                let lastHeartbeat = (data["lastHeartbeat"] as? Timestamp)?.dateValue() ?? .distantPast
                guard lastHeartbeat > cutoff else { return nil }

                let peerGenderRaw = data["gender"] as? String ?? ""
                let peerGender = Gender(rawValue: peerGenderRaw)
                let peerShowMeRaw = data["showMe"] as? String ?? ShowMe.everyone.rawValue
                let peerShowMe = ShowMe(rawValue: peerShowMeRaw) ?? .everyone

                // Mutual-preference gate: I must want them, they must want me.
                if let peerGender = peerGender, !myShowMe.matches(peerGender) { return nil }
                if let myGender = myGender, !peerShowMe.matches(myGender) { return nil }

                let joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()

                let candidate = QueueCandidate(
                    interests: data["interests"] as? [String] ?? [],
                    trustScore: data["trustScore"] as? Int ?? 50,
                    accountAgeDays: data["accountAgeDays"] as? Int ?? 0
                )

                return QueueEntry(
                    uid: uid,
                    displayName: data["displayName"] as? String ?? "",
                    photoUrl: (data["photoUrl"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    joinedAt: joinedAt,
                    candidate: candidate
                )
            }
        } catch {
            return []
        }
    }

    /// Runs a Firestore transaction that flips both queue entries to "matched"
    /// and creates the session doc. Returns true on success.
    private func attemptTransaction(me: User, myUID: String, peer: QueueEntry) async -> Bool {
        let sessionID = [myUID, peer.uid].sorted().joined(separator: "_") + "_" + String(Int(Date().timeIntervalSince1970))
        let myRef = db.collection(queueCollection).document(myUID)
        let peerRef = db.collection(queueCollection).document(peer.uid)
        let sessionRef = db.collection(sessionsCollection).document(sessionID)

        return await withCheckedContinuation { continuation in
            db.runTransaction({ (txn, errorPointer) -> Any? in
                do {
                    let mySnap = try txn.getDocument(myRef)
                    let peerSnap = try txn.getDocument(peerRef)
                    // Either side may have already been paired by the time
                    // we get the lock — bail cleanly so the caller retries.
                    guard (mySnap.get("status") as? String) == "waiting",
                          (peerSnap.get("status") as? String) == "waiting" else {
                        return false
                    }

                    txn.updateData([
                        "status": "matched",
                        "sessionID": sessionID,
                        "lastHeartbeat": FieldValue.serverTimestamp()
                    ], forDocument: myRef)

                    txn.updateData([
                        "status": "matched",
                        "sessionID": sessionID,
                        "lastHeartbeat": FieldValue.serverTimestamp()
                    ], forDocument: peerRef)

                    txn.setData([
                        "sessionID": sessionID,
                        "participants": [myUID, peer.uid],
                        "createdAt": FieldValue.serverTimestamp(),
                        "mode": "mock",
                        "status": "pending"
                    ], forDocument: sessionRef)

                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false
                }
            }) { result, _ in
                continuation.resume(returning: (result as? Bool) == true)
            }
        }
    }

    // MARK: - Enter session

    private func enterSession(sid: String, uid: String) async {
        // Cancel further scanning + heartbeating; we're in a session now.
        scanTask?.cancel(); scanTask = nil
        heartbeatTask?.cancel(); heartbeatTask = nil

        // Pull the session doc to identify which UID is the partner.
        let sessionSnap = try? await db.collection(sessionsCollection).document(sid).getDocument()
        let participants = sessionSnap?.data()?["participants"] as? [String] ?? []
        let mode = sessionSnap?.data()?["mode"] as? String ?? "mock"
        guard let partnerUID = participants.first(where: { $0 != uid }) else {
            status = .failed("Session is malformed.")
            return
        }

        // Load the partner's queue snapshot for display data; fall back to
        // the users/{uid} doc if the queue entry is already gone. Split
        // across two statements because Swift's async inference doesn't
        // propagate through nested try?-await inside a nil-coalescing
        // expression — collapsing the fallback into one line compiles as
        // "async call in non-concurrency context".
        let partnerQueue = try? await db.collection(queueCollection).document(partnerUID).getDocument()
        let partnerData: [String: Any]
        if let queueData = partnerQueue?.data() {
            partnerData = queueData
        } else if let userSnap = try? await db.collection("users").document(partnerUID).getDocument(),
                  let userData = userSnap.data() {
            partnerData = userData
        } else {
            partnerData = [:]
        }

        let name = partnerData["displayName"] as? String
            ?? partnerData["display_name"] as? String
            ?? "Your match"
        let photo = (partnerData["photoUrl"] as? String) ?? (partnerData["profile_photo_url"] as? String)
        let partnerInterests = partnerData["interests"] as? [String] ?? []

        // My interests — pulled from the caller's User snapshot via the
        // queue (we just wrote it in writeQueueEntry).
        let myQueue = try? await db.collection(queueCollection).document(uid).getDocument()
        let myInterests = myQueue?.data()?["interests"] as? [String] ?? []

        let lowerMine = Set(myInterests.map { $0.lowercased() })
        let shared = partnerInterests.filter { lowerMine.contains($0.lowercased()) }

        let session = MatchSession(
            sessionID: sid,
            partnerUID: partnerUID,
            partnerName: name,
            partnerPhotoUrl: photo?.isEmpty == false ? photo : nil,
            partnerSubtitle: nil, // we don't store class/year on users yet
            sharedInterests: shared,
            mode: mode
        )

        status = .matched(session: session)
        isSearching = false
    }
}

// MARK: - Value types

private struct QueueEntry {
    let uid: String
    let displayName: String
    let photoUrl: String?
    let joinedAt: Date
    let candidate: QueueCandidate
}

private struct QueueCandidate: MatchCandidate {
    let interests: [String]
    let trustScore: Int
    let accountAgeDays: Int
}
