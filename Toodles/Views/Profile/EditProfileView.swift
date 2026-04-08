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
        ScrollView {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    photoPickerLabel
                }
                Text("Upload profile picture").font(.caption).foregroundStyle(.secondary)

                nameField
                bioField
                interestsField

                if let err = errorMessage {
                    Text(err).foregroundStyle(.red).font(.callout).multilineTextAlignment(.center)
                }

                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save Changes")
                    }
                }
                .buttonStyle(ToodlesPrimaryButtonStyle())
                .disabled(isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Subviews

    private var photoPickerLabel: some View {
        ZStack {
            Circle().fill(.blue.opacity(0.2)).frame(width: 120, height: 120)
            if let img = pickedImage {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else if let url = userViewModel.currentUser?.profilePhotoUrl,
                      !url.isEmpty,
                      let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: { ProgressView() }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Circle()
                .fill(.orange)
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "camera.fill").foregroundStyle(.white))
                .offset(x: 40, y: 40)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Name").font(.caption).foregroundStyle(.secondary)
            TextField("Display name", text: $displayName)
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.3)))
        }
    }

    private var bioField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bio").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $bio)
                .frame(height: 90)
                .padding(8)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.3)))
            Text("\(bio.count)/150").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var interestsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interests").font(.caption).foregroundStyle(.secondary)
            HStack {
                TextField("Add an interest", text: $newInterest)
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.3)))
                Button("Add") {
                    let t = newInterest.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty && !interests.contains(t) {
                        interests.append(t)
                        newInterest = ""
                    }
                }
                .buttonStyle(.borderedProminent).tint(.blue)
            }
            // Interest tags wrap naturally using HStacks stacked in rows of 3
            let rows = interests.chunked(into: 3)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 6) {
                        ForEach(rows[rowIndex], id: \.self) { item in
                            HStack(spacing: 4) {
                                Text(item).font(.caption)
                                Image(systemName: "xmark").font(.caption2)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.blue.opacity(0.15))
                            .clipShape(Capsule())
                            .onTapGesture { interests.removeAll { $0 == item } }
                        }
                    }
                }
            }
        }
    }

    private var initials: String {
        let name = displayName.isEmpty ? (userViewModel.currentUser?.displayName ?? "U") : displayName
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Save

    private func save() {
        guard let uid = AuthManager.shared.currentUID else { return }
        isSaving = true
        errorMessage = nil

        let persistProfile: (String?) -> Void = { photoUrl in
            var data: [String: Any] = [
                "display_name": displayName,
                "bio": String(bio.prefix(150)),
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

// MARK: - Array chunking helper (used for interest tag wrapping)
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
