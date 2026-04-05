import Foundation
import FirebaseFirestore

// MARK: - User

struct User: Codable, Identifiable {
    @DocumentID var documentID: String?
    var userId: String
    var eduEmail: String
    var displayName: String
    var bio: String
    var toastScore: Int

    var id: String { userId }

    static func create(userId: String, eduEmail: String, displayName: String) -> User {
        return User(
            userId: userId,
            eduEmail: eduEmail,
            displayName: displayName,
            bio: "",
            toastScore: 100
        )
    }
}

// MARK: - Match

enum MatchStatus: String, Codable {
    case matched
    case rejected
    case added
}

struct Match: Codable, Identifiable {
    @DocumentID var documentID: String?
    var matchId: String
    var userAId: String
    var userBId: String
    var matchedAt: Date
    var status: MatchStatus

    var id: String { matchId }

    func otherUserId(currentUID: String) -> String? {
        if userAId == currentUID { return userBId }
        if userBId == currentUID { return userAId }
        return nil
    }
}

// MARK: - Chat

struct Chat: Codable, Identifiable {
    @DocumentID var documentID: String?
    var chatId: String
    var matchId: String

    var id: String { chatId }
}

// MARK: - Message

struct Message: Codable, Identifiable {
    @DocumentID var documentID: String?
    var messageId: String
    var chatId: String
    var senderId: String
    var text: String
    var sentAt: Date

    var id: String { messageId }

    static func create(chatId: String, senderId: String, text: String) -> Message {
        return Message(
            messageId: UUID().uuidString,
            chatId: chatId,
            senderId: senderId,
            text: text,
            sentAt: Date()
        )
    }
}

// MARK: - Support Ticket

enum TicketCategory: String, Codable {
    case reportIssue = "report_issue"
    case feedback
    case techHelp = "tech_help"
}

enum TicketStatus: String, Codable {
    case submitted
    case inReview = "in_review"
    case resolved
}

struct SupportTicket: Codable, Identifiable {
    @DocumentID var documentID: String?
    var ticketId: String
    var userId: String
    var subject: String
    var description: String
    var category: TicketCategory
    var status: TicketStatus

    var id: String { ticketId }

    static func create(userId: String, subject: String, description: String, category: TicketCategory) -> SupportTicket {
        return SupportTicket(
            ticketId: UUID().uuidString,
            userId: userId,
            subject: subject,
            description: description,
            category: category,
            status: .submitted
        )
    }
}
