import Foundation
import FirebaseFirestore

// MARK: - User (ERD: USER entity)
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var bio: String
    var interests: [String]
    var profilePhotoUrl: String?
    var trustScore: Int
    var verified: Bool
    var createdAt: Date

    static var empty: User {
        User(
            id: nil,
            email: "",
            displayName: "",
            bio: "",
            interests: [],
            profilePhotoUrl: nil,
            trustScore: 100,
            verified: false,
            createdAt: Date()
        )
    }
}

// MARK: - Match (ERD: MATCH entity)
struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    var user_a_id: String
    var user_b_id: String
    var matched_at: Date
    var status: String  // "matched" | "rejected" | "added" | "reported"
}

// MARK: - Chat (ERD: CHAT entity — intermediary)
struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    var match_id: String
    var participant_ids: [String]
    var last_message: String?
    var last_message_at: Date?
}

// MARK: - Message (ERD: MESSAGE subcollection)
struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var chat_id: String
    var sender_id: String
    var text: String
    var sent_at: Date
}

// MARK: - Support Ticket (ERD: SUPPORT_TICKET entity)
struct SupportTicket: Identifiable, Codable {
    @DocumentID var id: String?
    var user_id: String
    var subject: String
    var description: String
    var category: String  // "report_user" | "feedback" | "tech_help"
    var status: String    // "submitted" | "in_review" | "resolved"
    var created_at: Date
}
