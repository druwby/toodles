import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {

    @DocumentID var id: String?

    var email: String
    var username: String
    var verified: Bool
    var createdAt: Date
}
