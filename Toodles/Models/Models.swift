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

// MARK: - Trust Event (TDV-83 / Subproject D)
//
// Immutable audit record for every delta applied to a user's trust score.
// The subject's score is recomputed from the full event history rather than
// mutated in place — that way scoring logic can evolve without back-filling
// old writes and a single event is never "forgotten" mid-calculation.

enum TrustEventKind: String, Codable, CaseIterable {
    case positiveSessionCompleted = "positive_session"
    case neutralSessionCompleted  = "neutral_session"
    case reportedBySomeone        = "reported_by_someone"
    case reportedSomeone          = "reported_someone"
    case profileCompleted         = "profile_completed"
    case emailVerified            = "email_verified"
    case addedInterests           = "added_interests"
    case weeklyDecay              = "weekly_decay"

    /// Points delta applied to the subject's score when this event is recorded.
    /// Sum of deltas + base score = final score (clamped 0...100).
    var delta: Int {
        switch self {
        case .positiveSessionCompleted: return  2
        case .neutralSessionCompleted:  return  0
        case .reportedBySomeone:        return -8
        case .reportedSomeone:          return  1
        case .profileCompleted:         return  4
        case .emailVerified:            return 10
        case .addedInterests:           return  3
        case .weeklyDecay:              return -1
        }
    }

    /// User-facing label for the recovery and activity UIs.
    var displayName: String {
        switch self {
        case .positiveSessionCompleted: return "Good conversation"
        case .neutralSessionCompleted:  return "Neutral session"
        case .reportedBySomeone:        return "Someone reported you"
        case .reportedSomeone:          return "Flagged bad behavior"
        case .profileCompleted:         return "Completed profile"
        case .emailVerified:            return "Verified CSUF email"
        case .addedInterests:           return "Added interests"
        case .weeklyDecay:              return "Inactivity"
        }
    }
}

struct TrustEvent: Identifiable, Codable {
    @DocumentID var id: String?
    /// UID whose score is affected.
    var subject: String
    /// UID who triggered the event. For self-service actions like
    /// profileCompleted, actor == subject. For reportedBySomeone the actor
    /// is the reporter.
    var actor: String
    var kindRaw: String
    var delta: Int
    var createdAt: Date
    var sessionID: String?
    var note: String?

    var kind: TrustEventKind? { TrustEventKind(rawValue: kindRaw) }
}
