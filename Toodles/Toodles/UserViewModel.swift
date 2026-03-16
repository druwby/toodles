import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?

    private let authManager = AuthManager.shared
    private let firestoreService = FirestoreService.shared

    func login() {
        authManager.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isAuthenticated = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signup() {
        authManager.signup(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let uid):
                    self.createUserProfile(uid: uid)
                    self.isAuthenticated = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func createUserProfile(uid: String) {

        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "username": username,
            "createdAt": Timestamp()
        ]

        firestoreService.createUser(uid: uid, data: userData)
    }

    func logout() {
        authManager.logout()
        isAuthenticated = false
    }
}
