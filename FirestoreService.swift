import Foundation
import FirebaseFirestore

class FirestoreService {

    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Create User
    func createUser(uid: String, data: [String: Any]) {

        db.collection("users").document(uid).setData(data) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else {
                print("User profile created successfully")
            }
        }
    }

    // MARK: - Fetch User
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
}
