import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

final class UserViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    private let authManager = AuthManager.shared
    private let firestoreService = FirestoreService.shared

    init() {
        checkAuthState()
    }

    // MARK: - Auth state
    func checkAuthState() {
        isAuthenticated = authManager.isSignedIn
        if let uid = authManager.currentUID {
            loadProfile(uid: uid)
        }
    }

    // MARK: - Signup
    func signup() {
        errorMessage = nil
        authManager.signup(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
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

    // MARK: - Login
    func login() {
        errorMessage = nil
        authManager.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.isAuthenticated = true
                    if let uid = self.authManager.currentUID {
                        self.loadProfile(uid: uid)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Logout
    func logout() {
        authManager.logout()
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Create Firestore profile
    private func createUserProfile(uid: String) {
        let fallbackName = email.components(separatedBy: "@").first ?? "User"
        let chosenName = displayName.isEmpty ? fallbackName : displayName
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "display_name": chosenName,
            "bio": "",
            "interests": [],
            "profile_photo_url": "",
            "trust_score": 100,
            "verified": true,   // auto-verified via email domain check
            "created_at": Timestamp()
        ]
        firestoreService.createUser(uid: uid, data: userData)
        // Populate local state immediately so the tabbed UI has something to show
        currentUser = User(
            id: uid,
            email: email,
            displayName: chosenName,
            bio: "",
            interests: [],
            profilePhotoUrl: nil,
            trustScore: 100,
            verified: true,
            createdAt: Date()
        )
    }

    // MARK: - Load profile
    func loadProfile(uid: String) {
        firestoreService.fetchUser(uid: uid) { [weak self] data in
            DispatchQueue.main.async {
                guard let self = self, let data = data else { return }
                self.currentUser = User(
                    id: uid,
                    email: data["email"] as? String ?? "",
                    displayName: data["display_name"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    interests: data["interests"] as? [String] ?? [],
                    profilePhotoUrl: data["profile_photo_url"] as? String,
                    trustScore: data["trust_score"] as? Int ?? 100,
                    verified: data["verified"] as? Bool ?? false,
                    createdAt: (data["created_at"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        }
    }
}
