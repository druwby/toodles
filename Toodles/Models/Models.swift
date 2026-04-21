import Foundation
import FirebaseFirestore

// MARK: - Gender identity + matchmaking preference

/// How the user identifies. Stored as the raw string in Firestore.
enum Gender: String, CaseIterable, Codable, Identifiable {
    case woman
    case man
    case nonBinary = "non_binary"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .woman:     return "Woman"
        case .man:       return "Man"
        case .nonBinary: return "Non-binary"
        }
    }

    var shortLabel: String {
        switch self {
        case .woman:     return "W"
        case .man:       return "M"
        case .nonBinary: return "NB"
        }
    }
}

/// Who the user wants to match with. Everyone = no gender filter.
enum ShowMe: String, CaseIterable, Codable, Identifiable {
    case women
    case men
    case everyone

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .women:    return "Women"
        case .men:      return "Men"
        case .everyone: return "Everyone"
        }
    }

    /// Does this preference match a peer of the given gender?
    func matches(_ gender: Gender) -> Bool {
        switch self {
        case .women:    return gender == .woman
        case .men:      return gender == .man
        case .everyone: return true
        }
    }
}

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
    /// User's own gender identity. Nil when the user hasn't completed the
    /// profile-setup gate yet — ContentView uses that to keep the gate up.
    var gender: Gender?
    /// Who the user is interested in matching with. Nil = not yet picked.
    var showMe: ShowMe?

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
            createdAt: Date(),
            gender: nil,
            showMe: nil
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
