import SwiftUI
import PhotosUI

/// Hard-gate shown immediately after first sign-up (or on any login where the
/// user hasn't uploaded a profile photo yet). Mirrors the Hinge/Tinder pattern
/// where a user cannot browse, match, or chat without a visible face — in
/// Toodles this is load-bearing for the "verified real students" product thesis.
struct ProfileSetupView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var interests: [String] = []
    @State private var newInterest: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var photoIsSet: Bool {
        pickedImage != nil ||
        !(userViewModel.currentUser?.profilePhotoUrl ?? "").isEmpty
    }

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .heavy)

            ScrollView {
                VStack(spacing: 22) {
                    header
                        .padding(.top, 60)

                    photoPicker
                        .padding(.top, 4)

                    Text("Tap to add a photo of yourself")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))

                    formCard

                    if let err = errorMessage {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    continueButton
                        .padding(.top, 8)

                    whyCopy
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            if let u = userViewModel.currentUser {
                displayName = u.displayName
                bio = u.bio
                interests = u.interests
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    pickedImage = img
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 50))
                .foregroundStyle(.white)
            Text("One last thing")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Toodles only shows you to other verified CSUF students — which means we need a photo of you first.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    // MARK: - Photo picker

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 160, height: 160)

                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                } else if let url = userViewModel.currentUser?.profilePhotoUrl,
                          !url.isEmpty,
                          let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Circle()
                    .fill(ToodlesTheme.accent)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: pickedImage != nil ? "checkmark" : "plus")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    )
                    .offset(x: -4, y: -4)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 5)
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Display name")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                TextField("What should we call you?", text: $displayName)
                    .padding(10)
                    .background(Color(white: 0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .textContentType(.name)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Bio")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                    Spacer()
                    Text("Optional")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                TextEditor(text: $bio)
                    .frame(height: 64)
                    .padding(6)
                    .background(Color(white: 0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .scrollContentBackground(.hidden)
                Text("\(bio.count)/200 characters")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Interests")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                    Spacer()
                    Text("Optional")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                HStack(spacing: 8) {
                    TextField("Add an interest", text: $newInterest)
                        .padding(10)
                        .background(Color(white: 0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("Add") {
                        let t = newInterest.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty && !interests.contains(t) && interests.count < 8 {
                            interests.append(t)
                            newInterest = ""
                        }
                    }
                    .font(.callout.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(ToodlesTheme.bodyTop)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(newInterest.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !interests.isEmpty {
                    interestChips
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var interestChips: some View {
        // Simple wrap layout — uses FlowLayout if you've added it elsewhere.
        let rows = interests.chunked(into: 3)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<rows.count, id: \.self) { i in
                HStack(spacing: 6) {
                    ForEach(rows[i], id: \.self) { interest in
                        HStack(spacing: 4) {
                            Text(interest)
                                .font(.caption)
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .foregroundStyle(ToodlesTheme.avatarText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ToodlesTheme.chipBlue)
                        .clipShape(Capsule())
                        .onTapGesture {
                            interests.removeAll { $0 == interest }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Continue button

    private var continueButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Continue")
                        .font(.title3.bold())
                    Image(systemName: "arrow.right")
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(photoIsSet ? ToodlesTheme.accent : Color.gray.opacity(0.5))
            .clipShape(Capsule())
            .shadow(color: (photoIsSet ? ToodlesTheme.accent : Color.clear).opacity(0.5), radius: 10, y: 4)
        }
        .disabled(!photoIsSet || isSaving)
    }

    private var whyCopy: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                Text("Photo required · bio and interests can be added later")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.8))
            Text("Your photo is visible only to other verified CSUF students.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Save

    private func save() {
        guard let uid = AuthManager.shared.currentUID else {
            errorMessage = "You need to be signed in."
            return
        }
        guard photoIsSet else {
            errorMessage = "Please add a profile photo to continue."
            return
        }
        isSaving = true
        errorMessage = nil

        let persistProfile: (String?) -> Void = { photoUrl in
            var data: [String: Any] = [
                "display_name": displayName,
                "bio": String(bio.prefix(200)),
                "interests": interests
            ]
            if let url = photoUrl { data["profile_photo_url"] = url }
            FirestoreService.shared.updateUser(uid: uid, data: data) { err in
                DispatchQueue.main.async {
                    isSaving = false
                    if let err = err {
                        errorMessage = err.localizedDescription
                    } else {
                        // Reload so ContentView re-evaluates its gate condition
                        // and flips to MainTabView.
                        userViewModel.loadProfile(uid: uid)
                    }
                }
            }
        }

        if let img = pickedImage {
            StorageService.shared.uploadProfilePhoto(uid: uid, image: img) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url): persistProfile(url)
                    case .failure(let err):
                        isSaving = false
                        errorMessage = "Photo upload failed: \(err.localizedDescription)"
                    }
                }
            }
        } else {
            // User's existing Firestore profile already has a photo URL — just
            // persist whatever name/bio/interests they filled.
            persistProfile(nil)
        }
    }
}

// Local chunked helper — ProfileSetupView is self-contained.
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
