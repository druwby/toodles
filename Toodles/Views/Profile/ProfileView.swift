import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingEdit = false

    // Demo fallbacks — shown when the user's Firestore profile has empty bio/interests.
    // We don't mutate the user record; these are view-layer placeholders so the
    // Profile tab never looks empty during the demo.
    private var displayedBio: String {
        let bio = userViewModel.currentUser?.bio ?? ""
        return bio.isEmpty
            ? "CSU Fullerton student. Here for spontaneous 60-second conversations, not endless swiping."
            : bio
    }

    private var displayedInterests: [String] {
        let interests = userViewModel.currentUser?.interests ?? []
        return interests.isEmpty
            ? ["Coffee shops", "Hiking", "Indie music", "Anime", "Night drives"]
            : interests
    }

    private var displayedName: String {
        let name = userViewModel.currentUser?.displayName ?? ""
        if !name.isEmpty { return name }
        let email = userViewModel.currentUser?.email ?? ""
        let prefix = email.components(separatedBy: "@").first ?? ""
        return prefix.isEmpty ? "Student" : prefix
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ToodlesHeader(title: "Profile")

                ZStack {
                    AmbientOrbBackground(intensity: .soft)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Avatar + name + verified + trust
                            VStack(spacing: 12) {
                                avatar

                                Text(displayedName)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)

                                HStack(spacing: 10) {
                                    if userViewModel.currentUser?.verified == true {
                                        verifiedBadge
                                    }
                                    trustChip
                                }

                                if let email = userViewModel.currentUser?.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                            .padding(.top, 12)

                            // Stats row
                            HStack(spacing: 10) {
                                statCard(value: "24", label: "Sessions")
                                statCard(value: "6", label: "Matches")
                                statCard(value: "4", label: "Chats")
                            }
                            .padding(.horizontal, 16)

                            // About
                            sectionCard(title: "About") {
                                Text(displayedBio)
                                    .font(.callout)
                                    .foregroundStyle(.black.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Interests
                            sectionCard(title: "Interests") {
                                FlowLayout(spacing: 8) {
                                    ForEach(displayedInterests, id: \.self) { interest in
                                        Text(interest)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(ToodlesTheme.chipBlue)
                                            .foregroundStyle(ToodlesTheme.avatarText)
                                            .clipShape(Capsule())
                                    }
                                }
                            }

                            // Actions
                            VStack(spacing: 12) {
                                NavigationLink {
                                    EditProfileView()
                                } label: {
                                    actionRow(icon: "pencil", title: "Edit Profile", tint: .white, bg: ToodlesTheme.bodyTop.opacity(0.7))
                                }

                                Button {
                                    userViewModel.logout()
                                } label: {
                                    actionRow(icon: "arrow.right.square", title: "Sign Out", tint: .white, bg: Color.red.opacity(0.85))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Pieces

    private var avatar: some View {
        Group {
            if let url = userViewModel.currentUser?.profilePhotoUrl, !url.isEmpty,
               let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(ToodlesTheme.avatarBlue)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text(String(displayedName.prefix(2)).uppercased())
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(ToodlesTheme.avatarText)
                    )
            }
        }
        .overlay(
            Circle().stroke(Color.white.opacity(0.6), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    private var verifiedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("Verified CSUF")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var trustChip: some View {
        let score = userViewModel.currentUser?.trustScore ?? 100
        return HStack(spacing: 4) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.yellow)
            Text("Trust \(score)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 4)
            VStack {
                content()
            }
            .padding(14)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
    }

    private func actionRow(icon: String, title: String, tint: Color, bg: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.bold())
            Text(title)
                .font(.body.bold())
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .opacity(0.7)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Simple flow layout for interest chips

/// Wraps child views onto multiple lines when they overflow the parent width.
/// Used here for interest chips; kept private since it's only used by ProfileView.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowMaxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth {
                totalHeight += rowMaxHeight + spacing
                currentRowWidth = size.width + spacing
                rowMaxHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                rowMaxHeight = max(rowMaxHeight, size.height)
            }
            currentRowHeight = rowMaxHeight
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth == .infinity ? currentRowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
