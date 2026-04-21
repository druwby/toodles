import Foundation
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

    /// Hard cap on how long ContentView will wait for the Firestore profile to
    /// load before we fabricate a stub. Keeps Appetize sessions snappy even when
    /// Firestore is slow or offline.
    private static let profileLoadTimeoutSeconds: Double = 5.0

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
        // Fire a fallback stub in N seconds if Firestore never responds. This
        // prevents the ContentView splash from hanging forever on a slow Firestore
        // read or a missing user document.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.profileLoadTimeoutSeconds) { [weak self] in
            guard let self = self else { return }
            if self.isAuthenticated && self.currentUser == nil {
                self.currentUser = self.stubUser(uid: uid)
            }
        }

        firestoreService.fetchUser(uid: uid) { [weak self] data in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let data = data {
                    self.currentUser = User(
                        id: uid,
                        email: data["email"] as? String ?? self.authManager.currentEmail ?? "",
                        displayName: data["display_name"] as? String ?? "",
                        bio: data["bio"] as? String ?? "",
                        interests: data["interests"] as? [String] ?? [],
                        profilePhotoUrl: data["profile_photo_url"] as? String,
                        trustScore: data["trust_score"] as? Int ?? 100,
                        verified: data["verified"] as? Bool ?? false,
                        createdAt: (data["created_at"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } else {
                    // Firestore returned nil — the user doc doesn't exist (e.g. a
                    // signup where the createUser write was lost, or an edge Firestore
                    // read failure). Fall back to a stub so ProfileSetupView picks up
                    // and the user can complete their profile from scratch.
                    self.currentUser = self.stubUser(uid: uid)
                }
            }
        }
    }

    /// Minimal `User` built from the in-memory auth info. Used whenever
    /// Firestore can't tell us who the signed-in user is — the important
    /// thing is that `profilePhotoUrl` is nil, so ContentView routes the
    /// user to `ProfileSetupView` to fill in the details.
    private func stubUser(uid: String) -> User {
        let email = authManager.currentEmail ?? self.email
        let fallbackName = email.components(separatedBy: "@").first ?? ""
        return User(
            id: uid,
            email: email,
            displayName: fallbackName,
            bio: "",
            interests: [],
            profilePhotoUrl: nil,
            trustScore: 100,
            verified: true,
            createdAt: Date()
        )
    }
}
