import Foundation
import FirebaseFirestore

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    @DocumentID var documentID: String?
    var uid: String
    var displayName: String
    var email: String
    var bio: String
    var profileImageURL: String?
    var interests: [String]
    var createdAt: Date
    var updatedAt: Date
    
    var id: String { uid }
    
    /// Create a new profile with defaults
    static func create(uid: String, email: String, displayName: String) -> UserProfile {
        return UserProfile(
            uid: uid,
            displayName: displayName,
            email: email,
            bio: "",
            profileImageURL: nil,
            interests: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Match

struct Match: Codable, Identifiable {
    @DocumentID var documentID: String?
    var id: String
    var participants: [String]           // Array of two user UIDs
    var revealedFields: [String: [String]] // uid -> list of revealed profile fields
    var matchedAt: Date
    var lastMessage: String?
    var lastMessageAt: Date?
    
    /// Check if a specific user is part of this match
    func otherParticipant(currentUID: String) -> String? {
        return participants.first { $0 != currentUID }
    }
}

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable {
    @DocumentID var documentID: String?
    var id: String
    var senderUID: String
    var text: String
    var sentAt: Date
    
    static func create(senderUID: String, text: String) -> ChatMessage {
        return ChatMessage(
            id: UUID().uuidString,
            senderUID: senderUID,
            text: text,
            sentAt: Date()
        )
    }
}
