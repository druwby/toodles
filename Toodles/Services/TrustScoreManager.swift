// TrustScoreManager.swift
// Toodles
//
// TDV-74: Build TrustScoreManager with account verification logic
// TDV-83: Trust reward + recovery path (Subproject D of v1.1 roadmap)
//
// Scoring model:
//   baseScore(50) + verificationBonus + profileCompletenessBonus +
//   accountAgeBonus + sum(TrustEvent.delta for all events) - reportPenalty
//   clamped to [0, 100].
//
// Events are recorded in trustEvents/{eventID} as an immutable audit log.
// Recomputation reads all events for the subject and sums their deltas,
// which means adding a new event kind later doesn't require a backfill.

import Foundation
import FirebaseFirestore

enum VerificationStatus: String, Codable {
    case unverified = "unverified"
    case emailVerified = "email_verified"
    case phoneVerified = "phone_verified"
    case idVerified = "id_verified"
}

struct TrustScore: Codable {
    let uid: String
    var score: Double
    var verificationStatus: VerificationStatus
    var profileCompleteness: Double
    var accountAgeDays: Int
    var reportCount: Int
    var lastUpdated: Date

    var trustLevel: TrustLevel {
        switch score {
        case 80...100: return .high
        case 50..<80:  return .medium
        default:       return .low
        }
    }

    enum TrustLevel: String {
        case high   = "High Trust"
        case medium = "Medium Trust"
        case low    = "Low Trust"
    }
}

@MainActor
final class TrustScoreManager: ObservableObject {

    static let shared = TrustScoreManager()
    private let db = Firestore.firestore()

    @Published var currentUserTrustScore: TrustScore?
    @Published var isLoading = false

    private init() {}

    func calculateTrustScore(for uid: String) async throws -> TrustScore {
        isLoading = true
        defer { isLoading = false }

        let userDoc = try await db.collection("users").document(uid).getDocument()
        guard let data = userDoc.data() else {
            throw TrustScoreError.userNotFound
        }

        let reportCount = data["reportCount"] as? Int ?? 0
        // Accept both camelCase and snake_case createdAt — the two code paths
        // historically wrote different casings. Once the schema is unified
        // this fallback can be removed.
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            ?? (data["created_at"] as? Timestamp)?.dateValue()
            ?? Date()
        let accountAgeDays = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0

        // `??` binds tighter than `!=` in Swift, so the old
        //   `(data[...] as? String) ?? (...) != nil`
        // check returned true whenever the key *existed*, even for "". Signup
        // writes `"profile_photo_url": ""` for every new account, so every
        // user was auto-credited for profile completeness at signup. Guard
        // against empty strings explicitly.
        let photoStr = (data["profilePhotoURL"] as? String) ?? (data["profile_photo_url"] as? String) ?? ""
        let nameStr  = (data["displayName"] as? String)     ?? (data["display_name"] as? String)     ?? ""
        let hasPhoto = !photoStr.isEmpty
        let hasBio   = (data["bio"] as? String).map { !$0.isEmpty } ?? false
        let hasName  = !nameStr.isEmpty
        let completenessScore = [hasPhoto, hasBio, hasName].filter { $0 }.count

        let verificationRaw = data["verificationStatus"] as? String ?? "unverified"
        let verificationStatus = VerificationStatus(rawValue: verificationRaw) ?? .unverified

        var score: Double = Self.baseScore

        switch verificationStatus {
        case .idVerified:    score += 30
        case .phoneVerified: score += 20
        case .emailVerified: score += 10
        case .unverified:    break
        }

        score += Double(completenessScore) * (10.0 / 3.0)
        score += min(Double(accountAgeDays) / 18.0, 10.0)
        score -= Double(reportCount) * 5.0

        // Apply accumulated trust events (TDV-83). Each event contributes
        // its signed delta. This is what makes the score *change* over time
        // rather than being frozen at signup.
        let eventDelta = try await accumulatedEventDelta(for: uid)
        score += Double(eventDelta)

        score = max(0, min(100, score))

        let trustScore = TrustScore(
            uid: uid,
            score: score,
            verificationStatus: verificationStatus,
            profileCompleteness: Double(completenessScore) / 3.0,
            accountAgeDays: accountAgeDays,
            reportCount: reportCount,
            lastUpdated: Date()
        )

        try await db.collection("trustScores").document(uid).setData([
            "uid": uid,
            "score": score,
            "verificationStatus": verificationStatus.rawValue,
            "reportCount": reportCount,
            "lastUpdated": Timestamp(date: Date())
        ])

        // Previous versions mirrored score onto users/{uid}.trust_score, but
        // the Firestore rule forbids owner updates that touch trust_score
        // (guard against tampering). The mirror always failed silently under
        // try?. Callers now read TrustScoreManager directly or through
        // UserViewModel.refreshTrustScore() which updates the in-memory
        // copy. Server-side mirroring would need a Cloud Function — future
        // work.

        currentUserTrustScore = trustScore
        return trustScore
    }

    // MARK: - Reward + recovery events

    /// Base score before any bonuses or event deltas. Exposed as a static so
    /// tests can reference it directly.
    static let baseScore: Double = 50

    /// Record a trust event for `subject`. The current signed-in user is the
    /// actor unless overridden (e.g. a system-initiated weekly decay could
    /// pass a synthetic actor). Triggers a recalculation of the subject's
    /// score so the new delta is reflected immediately.
    @discardableResult
    func applyEvent(
        kind: TrustEventKind,
        for subject: String,
        actor: String? = nil,
        sessionID: String? = nil,
        note: String? = nil
    ) async throws -> TrustScore? {
        let effectiveActor = actor ?? AuthManager.shared.currentUID ?? subject
        let eventID = UUID().uuidString

        let data: [String: Any] = [
            "subject": subject,
            "actor": effectiveActor,
            "kindRaw": kind.rawValue,
            "delta": kind.delta,
            "createdAt": Timestamp(date: Date()),
            "sessionID": sessionID as Any,
            "note": note as Any
        ]
        try await db.collection("trustEvents").document(eventID).setData(data)

        // Recompute the subject's score. We deliberately re-fetch from users/
        // + trustEvents/ rather than doing an in-place delta — that's what
        // lets us add new event kinds without backfilling historical data.
        return try? await calculateTrustScore(for: subject)
    }

    /// Sum deltas of all recorded trust events for `uid`. Broken out so
    /// `calculateTrustScore` stays readable and so tests can target the
    /// aggregation logic directly.
    func accumulatedEventDelta(for uid: String) async throws -> Int {
        let snap = try await db.collection("trustEvents")
            .whereField("subject", isEqualTo: uid)
            .getDocuments()
        return snap.documents.reduce(0) { acc, doc in
            acc + ((doc.data()["delta"] as? Int) ?? 0)
        }
    }

    func verifyEmail(for uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "verificationStatus": VerificationStatus.emailVerified.rawValue
        ])
        _ = try await calculateTrustScore(for: uid)
    }

    func fetchTrustScore(for uid: String) async throws -> TrustScore? {
        let doc = try await db.collection("trustScores").document(uid).getDocument()
        guard let data = doc.data() else { return nil }

        return TrustScore(
            uid: uid,
            score: data["score"] as? Double ?? 0,
            verificationStatus: VerificationStatus(rawValue: data["verificationStatus"] as? String ?? "unverified") ?? .unverified,
            profileCompleteness: 0,
            accountAgeDays: 0,
            reportCount: data["reportCount"] as? Int ?? 0,
            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    enum TrustScoreError: Error {
        case userNotFound
        case calculationFailed
    }
}
