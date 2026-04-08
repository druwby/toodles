import Foundation
import FirebaseFirestore

/// Centralized Firestore access layer.
/// Note: `FirebaseFirestoreSwift` import removed — deprecated in Firebase 11+;
/// `@DocumentID` and Codable support moved into `FirebaseFirestore` itself.
final class FirestoreService {

    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Users

    func createUser(uid: String, data: [String: Any]) {
        db.collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else {
                print("User profile created successfully")
            }
        }
    }

    func fetchUser(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(snapshot?.data())
        }
    }

    func updateUser(uid: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("users").document(uid).updateData(data, completion: completion)
    }

    // MARK: - Matches

    func createMatch(userA: String, userB: String, status: String, completion: @escaping (String?) -> Void) {
        let matchId = UUID().uuidString
        let data: [String: Any] = [
            "match_id": matchId,
            "user_a_id": userA,
            "user_b_id": userB,
            "matched_at": Timestamp(),
            "status": status
        ]
        db.collection("matches").document(matchId).setData(data) { err in
            completion(err == nil ? matchId : nil)
        }
    }

    func matchesForUser(uid: String, completion: @escaping ([[String: Any]]) -> Void) {
        let q = db.collection("matches")
            .whereFilter(Filter.orFilter([
                Filter.whereField("user_a_id", isEqualTo: uid),
                Filter.whereField("user_b_id", isEqualTo: uid)
            ]))
            .order(by: "matched_at", descending: true)
        q.getDocuments { snap, _ in
            completion(snap?.documents.compactMap { $0.data() } ?? [])
        }
    }

    // MARK: - Messages

    func listenMessages(chatId: String, onChange: @escaping ([[String: Any]]) -> Void) -> ListenerRegistration {
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "sent_at", descending: false)
            .addSnapshotListener { snap, _ in
                onChange(snap?.documents.compactMap { $0.data() } ?? [])
            }
    }

    func sendMessage(chatId: String, senderId: String, text: String) {
        let msgId = UUID().uuidString
        let data: [String: Any] = [
            "message_id": msgId,
            "chat_id": chatId,
            "sender_id": senderId,
            "text": text,
            "sent_at": Timestamp()
        ]
        db.collection("chats").document(chatId).collection("messages").document(msgId).setData(data)
    }

    // MARK: - Support Tickets

    func createSupportTicket(userId: String, subject: String, description: String, category: String, completion: @escaping (Error?) -> Void) {
        let ticketId = UUID().uuidString
        let data: [String: Any] = [
            "ticket_id": ticketId,
            "user_id": userId,
            "subject": subject,
            "description": description,
            "category": category,
            "status": "submitted",
            "created_at": Timestamp()
        ]
        db.collection("supportTickets").document(ticketId).setData(data, completion: completion)
    }
}
