import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Users

    func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.userId).setData(from: user, merge: true)
    }

    func fetchUser(userId: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try snapshot.data(as: User.self)
    }

    func fetchCurrentUser() async throws -> User? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return try await fetchUser(userId: uid)
    }

    func listenToUser(userId: String, completion: @escaping (User?) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion(nil)
                return
            }
            let user = try? snapshot.data(as: User.self)
            completion(user)
        }
    }

    // MARK: - Matches

    func saveMatch(_ match: Match) async throws {
        try db.collection("matches").document(match.matchId).setData(from: match)
    }

    func fetchMatches(for userId: String) async throws -> [Match] {
        let snapshotA = try await db.collection("matches")
            .whereField("userAId", isEqualTo: userId)
            .getDocuments()

        let snapshotB = try await db.collection("matches")
            .whereField("userBId", isEqualTo: userId)
            .getDocuments()

        let matchesA = snapshotA.documents.compactMap { try? $0.data(as: Match.self) }
        let matchesB = snapshotB.documents.compactMap { try? $0.data(as: Match.self) }

        return (matchesA + matchesB).sorted { $0.matchedAt > $1.matchedAt }
    }

    func updateMatchStatus(matchId: String, status: MatchStatus) async throws {
        try await db.collection("matches").document(matchId).updateData([
            "status": status.rawValue
        ])
    }

    // MARK: - Chats

    func saveChat(_ chat: Chat) async throws {
        try db.collection("chats").document(chat.chatId).setData(from: chat)
    }

    func fetchChat(chatId: String) async throws -> Chat? {
        let snapshot = try await db.collection("chats").document(chatId).getDocument()
        return try snapshot.data(as: Chat.self)
    }

    func fetchChat(forMatchId matchId: String) async throws -> Chat? {
        let snapshot = try await db.collection("chats")
            .whereField("matchId", isEqualTo: matchId)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { try? $0.data(as: Chat.self) }
    }

    // MARK: - Messages

    func sendMessage(_ message: Message) async throws {
        try db.collection("chats").document(message.chatId)
            .collection("messages").document(message.messageId)
            .setData(from: message)
    }

    func listenToMessages(chatId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion([])
                    return
                }
                let messages = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                completion(messages)
            }
    }

    // MARK: - Support Tickets

    func saveTicket(_ ticket: SupportTicket) async throws {
        try db.collection("supportTickets").document(ticket.ticketId).setData(from: ticket)
    }

    func fetchTickets(for userId: String) async throws -> [SupportTicket] {
        let snapshot = try await db.collection("supportTickets")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: SupportTicket.self) }
    }

    func updateTicketStatus(ticketId: String, status: TicketStatus) async throws {
        try await db.collection("supportTickets").document(ticketId).updateData([
            "status": status.rawValue
        ])
    }
}
