import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var interests: [String] = []
    @State private var newInterest: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ToodlesHeader(
                title: "Edit Profile",
                showBackButton: true,
                onBack: { dismiss() }
            )

            ZStack {
                ToodlesTheme.bodyGradient.ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            photoPicker
                                .padding(.top, 20)

                            Text("Upload profile picture")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.85))

                            // Single white card containing all form fields
                            formCard

                            if let err = errorMessage {
                                Text(err)
                                    .foregroundStyle(.red)
                                    .font(.callout)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }

                    // Pinned Save Changes button
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                        } else {
                            Text("Save Changes")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                    }
                    .background(ToodlesTheme.accent)
                    .disabled(isSaving)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Photo picker

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(ToodlesTheme.avatarBlue)
                    .frame(width: 110, height: 110)
                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else if let url = userViewModel.currentUser?.profilePhotoUrl,
                          !url.isEmpty,
                          let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { ProgressView() }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                } else {
                    Text(initials)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(ToodlesTheme.avatarText)
                }
                Circle()
                    .fill(ToodlesTheme.accent)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    )
                    .offset(x: -4, y: -4)
            }
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                TextField("Display name", text: $displayName)
                    .padding(10)
                    .background(Color(white: 0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Bio
            VStack(alignment: .leading, spacing: 6) {
                Text("Bio")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                TextEditor(text: $bio)
                    .frame(height: 80)
                    .padding(6)
                    .background(Color(white: 0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .scrollContentBackground(.hidden)
                Text("\(bio.count)/200 characters")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            // Interests
            VStack(alignment: .leading, spacing: 6) {
                Text("Interests")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                HStack(spacing: 8) {
                    TextField("Add an interest", text: $newInterest)
                        .padding(10)
                        .background(Color(white: 0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("Add") {
                        let t = newInterest.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty && !interests.contains(t) {
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
                }

                // Interest chips
                if !interests.isEmpty {
                    InterestChipsView(interests: $interests)
                    Text("Click on a tag to remove it")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var initials: String {
        let name = displayName.isEmpty ? (userViewModel.currentUser?.displayName ?? "U") : displayName
        return String(name.prefix(2)).uppercased()
    }

    private func save() {
        guard let uid = AuthManager.shared.currentUID else { return }
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
                        userViewModel.loadProfile(uid: uid)
                        dismiss()
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
            persistProfile(nil)
        }
    }
}

// MARK: - Interest chip wrap layout

private struct InterestChipsView: View {
    @Binding var interests: [String]

    var body: some View {
        // Simple 3-per-row wrap
        let rows = interests.chunked(into: 3)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex], id: \.self) { item in
                        HStack(spacing: 4) {
                            Text(item)
                                .font(.caption)
                                .foregroundStyle(ToodlesTheme.avatarText)
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundStyle(ToodlesTheme.avatarText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(ToodlesTheme.chipBlue)
                        .clipShape(Capsule())
                        .onTapGesture {
                            interests.removeAll { $0 == item }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
