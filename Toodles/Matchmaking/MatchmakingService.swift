// MatchmakingService.swift
// Toodles
// TDV-76: Implement MatchmakingService for real-time user pairing

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

enum MatchmakingStatus {
    case idle
    case searching
    case matched(partnerUID: String)
    case failed(Error)
}

@MainActor
class MatchmakingService: ObservableObject {
    @Published var status: MatchmakingStatus = .idle
    @Published var isSearching: Bool = false
    @Published var matchedPartnerUID: String?
    @Published var estimatedWaitTime: Int = 0
    private let db = Firestore.firestore()
    private var currentUserUID: String? { Auth.auth().currentUser?.uid }
    private let queueCollection = "matchmaking_queue"
    private let matchesCollection = "matches"
    
    func startSearching() async {
        guard let uid = currentUserUID else {
            status = .failed(MatchmakingError.notAuthenticated)
            return
        }
        isSearching = true
        status = .searching
        do {
            try await addToQueue(uid: uid)
            await findExistingMatch(uid: uid)
        } catch { isSearching = false; status = .failed(error) }
    }
    
    func cancelSearch() async {
        guard let uid = currentUserUID else { return }
        isSearching = false
        status = .idle
        try? await db.collection(queueCollection).document(uid).delete()
    }
    
    private func addToQueue(uid: String) async throws {
        let data: [String: Any] = ["uid": uid, "joinedAt": FieldValue.serverTimestamp(), "status": "waiting"]
        try await db.collection(queueCollection).document(uid).setData(data)
    }
    
    private func findExistingMatch(uid: String) async {
        do {
            let snapshot = try await db.collection(queueCollection)
                .whereField("status", isEqualTo: "waiting")
                .whereField("uid", isNotEqualTo: uid)
                .limit(to: 1).getDocuments()
            guard let partnerDoc = snapshot.documents.first else { return }
            try await createMatch(user1: uid, user2: partnerDoc.documentID)
        } catch { print("Match error: \(error)") }
    }
    
    private func createMatch(user1: String, user2: String) async throws {
        let matchID = [user1, user2].sorted().joined(separator: "_")
        let data: [String: Any] = ["matchID": matchID, "participants": [user1, user2], "createdAt": FieldValue.serverTimestamp(), "status": "pending"]
        try await db.collection(matchesCollection).document(matchID).setData(data)
    }
}

enum MatchmakingError: LocalizedError {
    case notAuthenticated, timeout
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "User is not authenticated."
        case .timeout: return "Matchmaking timed out."
        }
    }
}
