// SocialContinuityManager.swift
// Toodles
// TDV-32: Navigation Hub & Social Continuity

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct SessionState: Codable {
    let lastTab: Int
    let lastMatchID: String?
    let lastVisitedAt: Date
}

@MainActor
class SocialContinuityManager: ObservableObject {
    @Published var lastSessionState: SessionState? = nil
    @Published var hasActiveSession: Bool = false
    @Published var pendingReconnectMatchID: String? = nil

    private let db = Firestore.firestore()
    private var currentUserUID: String? { Auth.auth().currentUser?.uid }

    func restoreSession() async {
        guard let uid = currentUserUID else { return }
        do {
            let doc = try await db.collection("user_sessions").document(uid).getDocument()
            if let data = doc.data(),
               let lastTab = data["lastTab"] as? Int,
               let timestamp = (data["lastVisitedAt"] as? Timestamp)?.dateValue() {
                let state = SessionState(
                    lastTab: lastTab,
                    lastMatchID: data["lastMatchID"] as? String,
                    lastVisitedAt: timestamp
                )
                lastSessionState = state
                pendingReconnectMatchID = state.lastMatchID
                hasActiveSession = true
            }
        } catch {
            print("Failed to restore session: \(error)")
        }
    }

    func saveSession(tab: Int, matchID: String? = nil) async {
        guard let uid = currentUserUID else { return }
        let data: [String: Any] = [
            "lastTab": tab,
            "lastMatchID": matchID as Any,
            "lastVisitedAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection("user_sessions").document(uid).setData(data, merge: true)
    }

    func clearSession() async {
        guard let uid = currentUserUID else { return }
        try? await db.collection("user_sessions").document(uid).delete()
        lastSessionState = nil
        hasActiveSession = false
        pendingReconnectMatchID = nil
    }
}
