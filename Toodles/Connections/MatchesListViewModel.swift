// MatchesListViewModel.swift
// Toodles
// TDV-51: Create a "Matches List" interface displaying previous connections

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MatchesListViewModel: ObservableObject {
    @Published var matches: [MatchEntry] = []
    @Published var isLoading: Bool = false
    @Published var selectedMatch: MatchEntry? = nil
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var currentUserUID: String? { Auth.auth().currentUser?.uid }

    func loadMatches() async {
        guard let uid = currentUserUID else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("matches")
                .whereField("participants", arrayContains: uid)
                .order(by: "lastConnectedAt", descending: true)
                .limit(to: 50)
                .getDocuments()

            matches = snapshot.documents.compactMap { doc -> MatchEntry? in
                let data = doc.data()
                guard
                    let participants = data["participants"] as? [String],
                    let otherUID = participants.first(where: { $0 != uid }),
                    let displayName = data["displayName_\(otherUID)"] as? String,
                    let timestamp = (data["lastConnectedAt"] as? Timestamp)?.dateValue(),
                    let sessionID = data["sessionID"] as? String
                else { return nil }

                return MatchEntry(
                    id: doc.documentID,
                    displayName: displayName,
                    profileImageURL: data["profileImageURL_\(otherUID)"] as? String,
                    lastConnectedAt: timestamp,
                    sessionID: sessionID,
                    canReconnect: data["canReconnect"] as? Bool ?? true
                )
            }
        } catch {
            errorMessage = "Failed to load matches: \(error.localizedDescription)"
        }
    }

    func selectMatch(_ match: MatchEntry) {
        selectedMatch = match
    }
}
