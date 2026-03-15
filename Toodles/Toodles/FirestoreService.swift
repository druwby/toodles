import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    private let db = Firestore.firestore()
    
    // MARK: - User Profiles
    
    /// Save or update a user profile in Firestore
    func saveUserProfile(_ profile: UserProfile) async throws {
        try db.collection("users").document(profile.uid).setData(from: profile, merge: true)
    }
    
    /// Fetch a user profile by UID
    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return try snapshot.data(as: UserProfile.self)
    }
    
    /// Fetch the current authenticated user's profile
    func fetchCurrentUserProfile() async throws -> UserProfile? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return try await fetchUserProfile(uid: uid)
    }
    
    /// Listen for real-time updates to a user profile
    func listenToUserProfile(uid: String, completion: @escaping (UserProfile?) -> Void) -> ListenerRegistration {
        return db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion(nil)
                return
            }
            let profile = try? snapshot.data(as: UserProfile.self)
            completion(profile)
        }
    }
    
    // MARK: - Match History
    
    /// Save a new match between two users
    func saveMatch(_ match: Match) async throws {
        try db.collection("matches").document(match.id).setData(from: match)
    }
    
    /// Fetch all matches for the current user
    func fetchMatches(for uid: String) async throws -> [Match] {
        let snapshot = try await db.collection("matches")
            .whereField("participants", arrayContains: uid)
            .order(by: "matchedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Match.self)
        }
    }
    
    /// Listen for real-time match updates
    func listenToMatches(for uid: String, completion: @escaping ([Match]) -> Void) -> ListenerRegistration {
        return db.collection("matches")
            .whereField("participants", arrayContains: uid)
            .order(by: "matchedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion([])
                    return
                }
                let matches = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Match.self)
                }
                completion(matches)
            }
    }
    
    // MARK: - Chat Messages
    
    /// Send a chat message in a match conversation
    func sendMessage(_ message: ChatMessage, matchID: String) async throws {
        try db.collection("matches").document(matchID)
            .collection("messages").document(message.id)
            .setData(from: message)
        
        // Update the last message preview on the match document
        try await db.collection("matches").document(matchID).updateData([
            "lastMessage": message.text,
            "lastMessageAt": message.sentAt
        ])
    }
    
    /// Listen for real-time chat messages in a match conversation
    func listenToMessages(matchID: String, completion: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        return db.collection("matches").document(matchID)
            .collection("messages")
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion([])
                    return
                }
                let messages = snapshot.documents.compactMap { doc in
                    try? doc.data(as: ChatMessage.self)
                }
                completion(messages)
            }
    }
}
