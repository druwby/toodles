import Foundation
import FirebaseFirestore
import Combine

final class UserViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    /// Kept for back-compat with flows that still bind to displayName. New
    /// signup flow uses first/last and joins them for storage.
    @Published var displayName: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    private let authManager = AuthManager.shared
    private let firestoreService = FirestoreService.shared

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
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast  = lastName.trimmingCharacters(in: .whitespaces)
        let combinedName = [trimmedFirst, trimmedLast]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let fallbackFromEmail = email.components(separatedBy: "@").first ?? "User"
        let finalName = combinedName.isEmpty
            ? (displayName.isEmpty ? fallbackFromEmail : displayName)
            : combinedName

        // gender + show_me are deliberately NOT set here — they're collected
        // on the ProfileSetupView gate after signup so the account creation
        // call is fast and the gender/showMe selection is part of the same
        // "complete your profile" flow as the photo.
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "display_name": finalName,
            "first_name":  trimmedFirst,
            "last_name":   trimmedLast,
            "bio": "",
            "interests": [],
            "profile_photo_url": "",
            "trust_score": 100,
            "verified": true,
            "created_at": Timestamp()
        ]
        firestoreService.createUser(uid: uid, data: userData)
        let stubbed = User(
            id: uid,
            email: email,
            displayName: finalName,
            bio: "",
            interests: [],
            profilePhotoUrl: nil,
            trustScore: 100,
            verified: true,
            createdAt: Date(),
            gender: nil,
            showMe: nil
        )
        currentUser = stubbed
        cacheProfile(stubbed)
    }

    // MARK: - Load profile
    func loadProfile(uid: String) {
        // Timeout: if Firestore never calls back, fall back to cache or stub.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.profileLoadTimeoutSeconds) { [weak self] in
            guard let self = self else { return }
            if self.isAuthenticated && self.currentUser == nil {
                if let cached = self.cachedProfile(uid: uid) {
                    self.currentUser = cached
                } else {
                    self.currentUser = self.stubUser(uid: uid)
                }
            }
        }

        firestoreService.fetchUser(uid: uid) { [weak self] data in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let data = data {
                    let user = User(
                        id: uid,
                        email: data["email"] as? String ?? self.authManager.currentEmail ?? "",
                        displayName: data["display_name"] as? String ?? "",
                        bio: data["bio"] as? String ?? "",
                        interests: data["interests"] as? [String] ?? [],
                        profilePhotoUrl: data["profile_photo_url"] as? String,
                        trustScore: data["trust_score"] as? Int ?? 100,
                        verified: data["verified"] as? Bool ?? false,
                        createdAt: (data["created_at"] as? Timestamp)?.dateValue() ?? Date(),
                        gender: (data["gender"] as? String).flatMap { Gender(rawValue: $0) },
                        showMe: (data["show_me"] as? String).flatMap { ShowMe(rawValue: $0) }
                    )
                    self.currentUser = user
                    self.cacheProfile(user)
                    // users/{uid}.trust_score is only ever the signup-time
                    // value (the Firestore rule forbids owner updates that
                    // touch it). Recompute from trustEvents + structural
                    // state so the in-memory score is live before any
                    // matchmaking / trust-gate read.
                    self.refreshTrustScore(uid: uid)
                } else if let cached = self.cachedProfile(uid: uid) {
                    // Firestore read came back empty — fall back to the local
                    // UserDefaults cache of the last-known profile so the user
                    // doesn't get stuck on the setup gate across re-deploys.
                    self.currentUser = cached
                } else {
                    self.currentUser = self.stubUser(uid: uid)
                }
            }
        }
    }

    /// Recompute the user's trust score from TrustScoreManager and update the
    /// in-memory `currentUser`. Fire-and-forget — callers don't block on it.
    /// The Firestore rule forbids writing `users/{uid}.trust_score` from the
    /// client, so this in-memory refresh is how the app sees any change.
    func refreshTrustScore(uid: String) {
        Task { [weak self] in
            guard let self = self else { return }
            guard let ts = try? await TrustScoreManager.shared.calculateTrustScore(for: uid) else { return }
            await MainActor.run {
                guard var user = self.currentUser else { return }
                user.trustScore = Int(ts.score)
                self.currentUser = user
                self.cacheProfile(user)
            }
        }
    }

    /// Minimal `User` built from the in-memory auth info.
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
            createdAt: Date(),
            gender: nil,
            showMe: nil
        )
    }

    // MARK: - Local cache (UserDefaults)

    /// UserDefaults cache — survives app launches, not just the in-memory auth
    /// session. When a re-deploy spins up a brand-new Appetize simulator and
    /// Firestore is slow or the write hasn't propagated, the cache keeps the
    /// setup gate from re-triggering repeatedly.
    func cacheProfile(_ user: User) {
        guard let uid = user.id else { return }
        var payload: [String: Any] = [
            "email":             user.email,
            "display_name":      user.displayName,
            "bio":               user.bio,
            "interests":         user.interests,
            "profile_photo_url": user.profilePhotoUrl ?? "",
            "trust_score":       user.trustScore,
            "verified":          user.verified
        ]
        if let g = user.gender?.rawValue { payload["gender"] = g }
        if let s = user.showMe?.rawValue { payload["show_me"] = s }
        UserDefaults.standard.set(payload, forKey: Self.cacheKey(uid: uid))
    }

    private func cachedProfile(uid: String) -> User? {
        guard let data = UserDefaults.standard.dictionary(forKey: Self.cacheKey(uid: uid)) else {
            return nil
        }
        let photo = data["profile_photo_url"] as? String
        return User(
            id: uid,
            email: data["email"] as? String ?? authManager.currentEmail ?? "",
            displayName: data["display_name"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            interests: data["interests"] as? [String] ?? [],
            profilePhotoUrl: (photo?.isEmpty == false) ? photo : nil,
            trustScore: data["trust_score"] as? Int ?? 100,
            verified: data["verified"] as? Bool ?? true,
            createdAt: Date(),
            gender: (data["gender"] as? String).flatMap { Gender(rawValue: $0) },
            showMe: (data["show_me"] as? String).flatMap { ShowMe(rawValue: $0) }
        )
    }

    private static func cacheKey(uid: String) -> String {
        "toodles_profile_\(uid)"
    }
}
