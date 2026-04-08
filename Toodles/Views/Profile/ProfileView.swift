import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let url = userViewModel.currentUser?.profilePhotoUrl, !url.isEmpty,
                       let imageURL = URL(string: url) {
                        AsyncImage(url: imageURL) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ProgressView() }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                    } else {
                        Circle().fill(.blue.opacity(0.25)).frame(width: 140, height: 140)
                            .overlay(
                                Text(String((userViewModel.currentUser?.displayName ?? "U").prefix(2)).uppercased())
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                    }

                    Text(userViewModel.currentUser?.displayName ?? "Profile")
                        .font(.title.bold())
                    Text(userViewModel.currentUser?.email ?? "")
                        .foregroundStyle(.secondary)

                    if let bio = userViewModel.currentUser?.bio, !bio.isEmpty {
                        Text(bio).padding(.horizontal, 24).multilineTextAlignment(.center)
                    }

                    HStack {
                        ForEach(userViewModel.currentUser?.interests ?? [], id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    NavigationLink("Edit Profile") {
                        EditProfileView()
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

                    Button("Sign Out") { userViewModel.logout() }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Profile")
        }
    }
}
