// TDV-38: Create a profile editor for customizations and photos
// ProfileEditorViewModel.swift
// Toodles

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ProfileEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var pronouns: ProfilePronouns = .preferNotToSay
    @Published var lookingFor: RelationshipIntent = .dating
    @Published var selectedInterests: Set<String> = []
    @Published var selectedPhotos: [ProfilePhoto] = []

    // MARK: - UI State
    @Published var isSaving: Bool = false
    @Published var showPhotoPicker: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Private
    private var originalSnapshot: ProfileSnapshot?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var hasChanges: Bool {
        guard let snap = originalSnapshot else { return false }
        return displayName != snap.displayName
            || bio != snap.bio
            || pronouns != snap.pronouns
            || lookingFor != snap.lookingFor
            || selectedInterests != snap.interests
    }

    // MARK: - Load Profile
    func loadCurrentProfile() async {
        guard let uid = AuthService.shared.currentUID else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let data = doc.data() {
                displayName = data["displayName"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                pronouns = ProfilePronouns(rawValue: data["pronouns"] as? String ?? "") ?? .preferNotToSay
                lookingFor = RelationshipIntent(rawValue: data["lookingFor"] as? String ?? "") ?? .dating
                selectedInterests = Set(data["interests"] as? [String] ?? [])
                originalSnapshot = ProfileSnapshot(
                    displayName: displayName, bio: bio,
                    pronouns: pronouns, lookingFor: lookingFor,
                    interests: selectedInterests
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Save Profile
    func saveProfile() async {
        guard let uid = AuthService.shared.currentUID else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var updates: [String: Any] = [
                "displayName": displayName,
                "bio": bio,
                "pronouns": pronouns.rawValue,
                "lookingFor": lookingFor.rawValue,
                "interests": Array(selectedInterests),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            // Upload any new photos
            let uploadedURLs = try await uploadNewPhotos()
            if !uploadedURLs.isEmpty {
                updates["photoURLs"] = uploadedURLs
            }
            try await db.collection("users").document(uid).updateData(updates)
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Photo Upload
    private func uploadNewPhotos() async throws -> [String] {
        var urls: [String] = []
        for photo in selectedPhotos where photo.isNew {
            guard let data = photo.image.jpegData(compressionQuality: 0.8) else { continue }
            let ref = storage.reference().child("profile_photos/\(UUID().uuidString).jpg")
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            urls.append(url.absoluteString)
        }
        return urls
    }
}

// MARK: - Supporting Types
struct ProfileSnapshot {
    let displayName: String
    let bio: String
    let pronouns: ProfilePronouns
    let lookingFor: RelationshipIntent
    let interests: Set<String>
}

enum ProfilePronouns: String, CaseIterable {
    case heHim = "he/him"
    case sheHer = "she/her"
    case theyThem = "they/them"
    case preferNotToSay = "prefer_not_to_say"

    var displayText: String {
        switch self {
        case .heHim: return "He/Him"
        case .sheHer: return "She/Her"
        case .theyThem: return "They/Them"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum RelationshipIntent: String, CaseIterable {
    case dating = "dating"
    case friendships = "friendships"
    case casual = "casual"
    case longTerm = "long_term"

    var displayText: String {
        switch self {
        case .dating: return "Dating"
        case .friendships: return "Friendships"
        case .casual: return "Something casual"
        case .longTerm: return "Long-term relationship"
        }
    }
}
