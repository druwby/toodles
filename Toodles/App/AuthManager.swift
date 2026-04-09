import Foundation

/// Authentication manager using Firebase Auth REST API.
///
/// We use the REST API instead of the Firebase Auth iOS SDK because
/// Appetize.io's free-tier iOS Simulator blocks Keychain access, which
/// the SDK requires for token persistence. The REST API stores tokens
/// in memory only — sufficient for a demo session.
///
/// REST API docs: https://firebase.google.com/docs/reference/rest/auth
final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // MARK: - In-memory session (no Keychain)
    private(set) var currentUID: String?
    private var idToken: String?
    private var userEmail: String?

    var isSignedIn: Bool { currentUID != nil }

    // MARK: - Email Domain Validation
    static func isValidFullertonEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@(csu\.fullerton\.edu|fullerton\.edu)$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    // MARK: - Firebase API Key (read from GoogleService-Info.plist at runtime)
    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["API_KEY"] as? String else { return "" }
        return key
    }

    // MARK: - Signup (REST API)
    func signup(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard Self.isValidFullertonEmail(email) else {
            completion(.failure(AuthError.invalidDomain))
            return
        }
        guard password.count >= 6 else {
            completion(.failure(AuthError.weakPassword))
            return
        }

        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ])

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(AuthError.invalidResponse))
                return
            }

            // Check for REST API error
            if let errorInfo = json["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                completion(.failure(AuthError.server(Self.readableMessage(message))))
                return
            }

            guard let uid = json["localId"] as? String,
                  let token = json["idToken"] as? String else {
                completion(.failure(AuthError.noUID))
                return
            }

            self?.currentUID = uid
            self?.idToken = token
            self?.userEmail = email
            completion(.success(uid))
        }.resume()
    }

    // MARK: - Login (REST API)
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ])

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(AuthError.invalidResponse))
                return
            }

            if let errorInfo = json["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                completion(.failure(AuthError.server(Self.readableMessage(message))))
                return
            }

            if let uid = json["localId"] as? String,
               let token = json["idToken"] as? String {
                self?.currentUID = uid
                self?.idToken = token
                self?.userEmail = email
                completion(.success(()))
            } else {
                completion(.failure(AuthError.noUID))
            }
        }.resume()
    }

    // MARK: - Logout
    func logout() {
        currentUID = nil
        idToken = nil
        userEmail = nil
    }

    // MARK: - Helpers

    private static func readableMessage(_ raw: String) -> String {
        switch raw {
        case "EMAIL_EXISTS":
            return "The email address is already in use by another account."
        case "EMAIL_NOT_FOUND":
            return "No account found with this email."
        case "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
            return "Invalid email or password."
        case let s where s.hasPrefix("WEAK_PASSWORD"):
            return "Password must be at least 6 characters."
        case "TOO_MANY_ATTEMPTS_TRY_LATER":
            return "Too many attempts. Please try again later."
        default:
            return raw
        }
    }

    // MARK: - Error types
    enum AuthError: LocalizedError {
        case invalidDomain
        case weakPassword
        case invalidResponse
        case noUID
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidDomain:
                return "Please use a @csu.fullerton.edu or @fullerton.edu email."
            case .weakPassword:
                return "Password must be at least 6 characters."
            case .invalidResponse:
                return "Invalid response from the authentication server."
            case .noUID:
                return "Authentication succeeded but no user ID was returned."
            case .server(let msg):
                return msg
            }
        }
    }
}
