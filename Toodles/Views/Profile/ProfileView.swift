import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingEdit = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ToodlesHeader(title: "Profile")

                ZStack {
                    ToodlesTheme.bodyGradient.ignoresSafeArea(edges: .bottom)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Avatar
                            if let url = userViewModel.currentUser?.profilePhotoUrl, !url.isEmpty,
                               let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: { ProgressView() }
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(ToodlesTheme.avatarBlue)
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Text(String((userViewModel.currentUser?.displayName ?? "U").prefix(2)).uppercased())
                                            .font(.system(size: 48, weight: .semibold))
                                            .foregroundStyle(ToodlesTheme.avatarText)
                                    )
                            }

                            Text(userViewModel.currentUser?.displayName ?? "Profile")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text(userViewModel.currentUser?.email ?? "")
                                .foregroundStyle(.white.opacity(0.85))

                            if let bio = userViewModel.currentUser?.bio, !bio.isEmpty {
                                Text(bio)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .multilineTextAlignment(.center)
                            }

                            HStack {
                                ForEach(userViewModel.currentUser?.interests ?? [], id: \.self) { interest in
                                    Text(interest)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(ToodlesTheme.chipBlue)
                                        .foregroundStyle(ToodlesTheme.avatarText)
                                        .clipShape(Capsule())
                                }
                            }

                            NavigationLink("Edit Profile") {
                                EditProfileView()
                            }
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(ToodlesTheme.bodyTop.opacity(0.6))
                            .clipShape(Capsule())

                            Button("Sign Out") { userViewModel.logout() }
                                .font(.body.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
