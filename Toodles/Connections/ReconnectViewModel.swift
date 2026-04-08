// ReconnectViewModel.swift
// Toodles
// TDV-52: Implement a "Reconnect Tab" to continue conversations

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReconnectViewModel: ObservableObject {
    @Published var reconnectCandidates: [ReconnectCandidate] = []
    @Published var isLoading: Bool = false
    @Published var selectedReconnect: ReconnectCandidate? = nil
    @Published var errorMessage: String? = nil
    @Published var isInitiatingReconnect: Bool = false

    private let db = Firestore.firestore()
    private var currentUserUID: String? { Auth.auth().currentUser?.uid }

    func loadReconnectCandidates() async {
        guard let uid = currentUserUID else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("matches")
                .whereField("participants", arrayContains: uid)
                .whereField("reconnectEligible", isEqualTo: true)
                .order(by: "lastConnectedAt", descending: true)
                .limit(to: 30)
                .getDocuments()

            reconnectCandidates = snapshot.documents.compactMap { doc -> ReconnectCandidate? in
                let data = doc.data()
                guard
                    let participants = data["participants"] as? [String],
                    let otherUID = participants.first(where: { $0 != uid }),
                    let displayName = data["displayName_\(otherUID)"] as? String,
                    let timestamp = (data["lastConnectedAt"] as? Timestamp)?.dateValue(),
                    let matchID = data["matchID"] as? String
                else { return nil }

                return ReconnectCandidate(
                    id: doc.documentID,
                    displayName: displayName,
                    profileImageURL: data["profileImageURL_\(otherUID)"] as? String,
                    lastSessionDate: timestamp,
                    matchID: matchID,
                    mutualInterest: data["mutualInterest"] as? Bool ?? false
                )
            }
        } catch {
            errorMessage = "Failed to load reconnect options: \(error.localizedDescription)"
        }
    }

    func initiateReconnect(with candidate: ReconnectCandidate) async {
        guard let uid = currentUserUID else { return }
        isInitiatingReconnect = true
        defer { isInitiatingReconnect = false }

        do {
            let requestData: [String: Any] = [
                "initiatorUID": uid,
                "matchID": candidate.matchID,
                "requestedAt": FieldValue.serverTimestamp(),
                "status": "pending"
            ]
            try await db.collection("reconnect_requests").addDocument(data: requestData)
        } catch {
            errorMessage = "Failed to initiate reconnect: \(error.localizedDescription)"
        }
    }
}
