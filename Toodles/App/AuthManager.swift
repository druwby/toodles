import Foundation
import FirebaseAuth

final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // MARK: - Email Domain Validation
    /// Enforces @csu.fullerton.edu or @fullerton.edu per PDF FR-01 + Appendix II.
    static func isValidFullertonEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@(csu\.fullerton\.edu|fullerton\.edu)$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    // MARK: - Signup
    func signup(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard Self.isValidFullertonEmail(email) else {
            completion(.failure(NSError(domain: "AuthManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Please use a @csu.fullerton.edu or @fullerton.edu email."
            ])))
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(domain: "AuthManager", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Signup succeeded but no UID returned."
                ])))
                return
            }
            completion(.success(uid))
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Logout
    func logout() {
        try? Auth.auth().signOut()
    }

    // MARK: - Current user
    var currentUID: String? { Auth.auth().currentUser?.uid }
    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }
    var isSignedIn: Bool { Auth.auth().currentUser != nil }
}
