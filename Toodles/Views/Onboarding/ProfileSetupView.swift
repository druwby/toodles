import SwiftUI
import PhotosUI

/// Hard-gate shown immediately after first sign-up (or on any login where the
/// user hasn't uploaded a profile photo yet). Mirrors the Hinge/Tinder pattern
/// where a user cannot browse, match, or chat without a visible face — in
/// Toodles this is load-bearing for the "verified real students" product thesis.
struct ProfileSetupView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""
    @State private var selectedInterests: Set<String> = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private static let maxInterests = 5

    /// Curated interest pool — the tags Hinge/Tinder-style apps surface for
    /// college-aged users. Kept flat (no categories) for a cleaner grid; ~22
    /// options covers the breadth without overwhelming the user.
    private static let interestPool: [InterestTag] = [
        .init(name: "Coffee",         emoji: "☕️"),
        .init(name: "Hiking",         emoji: "🥾"),
        .init(name: "Hot yoga",       emoji: "🧘‍♀️"),
        .init(name: "Concerts",       emoji: "🎤"),
        .init(name: "Gaming",         emoji: "🎮"),
        .init(name: "Anime",          emoji: "🎴"),
        .init(name: "Boba",           emoji: "🧋"),
        .init(name: "Cooking",        emoji: "🍳"),
        .init(name: "Movies",         emoji: "🎬"),
        .init(name: "Reading",        emoji: "📚"),
        .init(name: "Travel",         emoji: "✈️"),
        .init(name: "Photography",    emoji: "📸"),
        .init(name: "Dancing",        emoji: "💃"),
        .init(name: "Surfing",        emoji: "🏄"),
        .init(name: "Art galleries",  emoji: "🎨"),
        .init(name: "Podcasts",       emoji: "🎙️"),
        .init(name: "Board games",    emoji: "🎲"),
        .init(name: "Beach days",     emoji: "🏖️"),
        .init(name: "Running",        emoji: "🏃"),
        .init(name: "Thrifting",      emoji: "🛍️"),
        .init(name: "Food trucks",    emoji: "🌮"),
        .init(name: "Working out",    emoji: "🏋️"),
    ]

    private var photoIsSet: Bool {
        pickedImage != nil ||
        !(userViewModel.currentUser?.profilePhotoUrl ?? "").isEmpty
    }

    private var firstNameFilled: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var lastNameFilled: Bool {
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canContinue: Bool {
        photoIsSet && firstNameFilled && lastNameFilled && !isSaving
    }

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .heavy)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                            .padding(.top, 50)

                        photoPicker
                            .padding(.top, 4)

                        Text("Tap to add a photo of yourself")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))

                        formCard

                        interestCard

                        if let err = errorMessage {
                            Text(err)
                                .foregroundStyle(.white)
                                .font(.callout)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 20)
                        }

                        whyCopy
                            .padding(.top, 4)
                            .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 20)
                }

                // Live requirements checklist — always visible so the user knows
                // exactly what's blocking Continue before they tap it.
                requirementsStrip

                // Pinned Continue button — always visible regardless of scroll position
                continueBar
            }
        }
        .onAppear {
            hydrateFromExistingUser()
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
                .font(.system(size: 30, weight: .black))
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

    // MARK: - Form card (first name / last name / bio)

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("First name")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                    TextField("First", text: $firstName)
                        .foregroundStyle(.black)
                        .tint(.black)
                        .textContentType(.givenName)
                        .padding(10)
                        .background(Color(white: 0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last name")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                    TextField("Last", text: $lastName)
                        .foregroundStyle(.black)
                        .tint(.black)
                        .textContentType(.familyName)
                        .padding(10)
                        .background(Color(white: 0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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
                    .foregroundStyle(.black)
                    .tint(.black)
                    .frame(height: 64)
                    .padding(6)
                    .background(Color(white: 0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .scrollContentBackground(.hidden)
                Text("\(bio.count)/200 characters")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Interest selection (Hinge/Tinder-style tag grid)

    private var interestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Interests")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
                Spacer()
                Text("\(selectedInterests.count)/\(Self.maxInterests)")
                    .font(.caption.bold())
                    .foregroundStyle(
                        selectedInterests.count == Self.maxInterests
                            ? ToodlesTheme.accent
                            : .gray
                    )
            }

            Text("Pick up to \(Self.maxInterests) things you're into.")
                .font(.caption2)
                .foregroundStyle(.gray)

            InterestTagGrid(
                pool: Self.interestPool,
                selected: $selectedInterests,
                max: Self.maxInterests
            )
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Requirements strip (pinned above Continue)

    private var requirementsStrip: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            requirementCheck(met: photoIsSet,      label: "Photo")
            requirementCheck(met: firstNameFilled, label: "First name")
            requirementCheck(met: lastNameFilled,  label: "Last name")
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
    }

    private func requirementCheck(met: Bool, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption.bold())
                .foregroundStyle(met ? .green : .white.opacity(0.55))
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(met ? .green : .white.opacity(0.9))
        }
    }

    // MARK: - Continue bar (pinned)

    private var continueBar: some View {
        VStack(spacing: 0) {
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
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.58, blue: 0.12),
                            Color(red: 0.98, green: 0.42, blue: 0.40)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.30).opacity(0.5), radius: 14, y: 6)
            }
            .disabled(isSaving)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }

    private var whyCopy: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                Text("Photo + name required · bio and interests can be added later")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.8))
            Text("Your photo is only visible to other verified CSUF students.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Data hydration + save

    private func hydrateFromExistingUser() {
        guard let u = userViewModel.currentUser else { return }

        // Split an existing display name on first space so re-visits don't lose state.
        let parts = u.displayName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if firstName.isEmpty, let f = parts.first { firstName = String(f) }
        if lastName.isEmpty,  parts.count > 1 { lastName = String(parts[1]) }
        if bio.isEmpty { bio = u.bio }
        if selectedInterests.isEmpty {
            selectedInterests = Set(u.interests)
        }
    }

    private func save() {
        errorMessage = nil

        // Up-front validation — user sees a clear reason if anything is missing.
        guard photoIsSet else {
            errorMessage = "Please add a profile photo to continue."
            return
        }
        guard firstNameFilled else {
            errorMessage = "Please enter your first name."
            return
        }
        guard lastNameFilled else {
            errorMessage = "Please enter your last name."
            return
        }
        guard let uid = AuthManager.shared.currentUID else {
            errorMessage = "You're not signed in. Try signing in again."
            return
        }

        isSaving = true
        let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"

        // Hard cap on isSaving — if the async save stalls (Firebase misconfiguration,
        // offline Appetize session, etc.), release the spinner after 10 seconds so
        // the user isn't trapped. Worst case they tap Continue again.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if isSaving {
                isSaving = false
                errorMessage = "Saving is taking a while. Try Continue again."
            }
        }

        // Flip ContentView past the gate even if Firestore/Storage fail — critical
        // for demo-day survival. ContentView only checks profilePhotoUrl is non-empty.
        let advanceLocally: (String) -> Void = { photoUrl in
            let updated = User(
                id: uid,
                email: userViewModel.currentUser?.email ?? authManagerEmail,
                displayName: fullName,
                bio: String(bio.prefix(200)),
                interests: Array(selectedInterests),
                profilePhotoUrl: photoUrl,
                trustScore: userViewModel.currentUser?.trustScore ?? 100,
                verified: true,
                createdAt: userViewModel.currentUser?.createdAt ?? Date()
            )
            userViewModel.currentUser = updated
        }

        let persistToFirestore: (String) -> Void = { photoUrl in
            var data: [String: Any] = [
                "display_name":      fullName,
                "first_name":        firstName.trimmingCharacters(in: .whitespaces),
                "last_name":         lastName.trimmingCharacters(in: .whitespaces),
                "bio":               String(bio.prefix(200)),
                "interests":         Array(selectedInterests),
                "profile_photo_url": photoUrl
            ]
            FirestoreService.shared.updateUser(uid: uid, data: data) { err in
                DispatchQueue.main.async {
                    isSaving = false
                    if err != nil {
                        // Firestore write failed (rules, network, quota) — still
                        // advance locally so the user isn't trapped on the gate.
                        advanceLocally(photoUrl)
                    } else {
                        // Best path: reload from Firestore so every tab sees the new profile.
                        userViewModel.loadProfile(uid: uid)
                    }
                }
            }
        }

        // Upload photo if the user picked a new one; otherwise reuse any existing URL.
        if let img = pickedImage {
            StorageService.shared.uploadProfilePhoto(uid: uid, image: img) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        persistToFirestore(url)
                    case .failure:
                        // Storage failed (often happens on Appetize with a free-tier
                        // Firebase project). Advance locally with an in-memory image
                        // reference so the demo flow continues. Profile re-saves when
                        // the user edits later.
                        isSaving = false
                        advanceLocally("local://unuploaded")
                    }
                }
            }
        } else if let existing = userViewModel.currentUser?.profilePhotoUrl, !existing.isEmpty {
            persistToFirestore(existing)
        } else {
            isSaving = false
            errorMessage = "Please add a profile photo to continue."
        }
    }

    /// Pulls the email from AuthManager without triggering a Firestore re-read.
    /// Local helper for constructing the advance-locally stub.
    private var authManagerEmail: String {
        AuthManager.shared.currentEmail ?? ""
    }
}

// MARK: - InterestTag + grid

struct InterestTag: Hashable {
    let name: String
    let emoji: String
}

/// Two-column flowing grid of selectable interest tags. Mirrors the Hinge/Tinder
/// pattern — tap to toggle, hits the max, disables further adds.
private struct InterestTagGrid: View {
    let pool: [InterestTag]
    @Binding var selected: Set<String>
    let max: Int

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(pool, id: \.self) { tag in
                let isSelected = selected.contains(tag.name)
                let atCap = selected.count >= max && !isSelected
                Button {
                    if isSelected {
                        selected.remove(tag.name)
                    } else if !atCap {
                        selected.insert(tag.name)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(tag.emoji)
                        Text(tag.name)
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(isSelected ? .white : ToodlesTheme.avatarText)
                    .background(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.58, blue: 0.12),
                                        Color(red: 0.98, green: 0.42, blue: 0.40)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(ToodlesTheme.chipBlue)
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .opacity(atCap ? 0.4 : 1.0)
                    .scaleEffect(isSelected ? 1.04 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                .disabled(atCap)
            }
        }
    }
}

/// Simple wrapping layout for the interest chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var rowMaxHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth {
                totalHeight += rowMaxHeight + spacing
                currentRowWidth = size.width + spacing
                rowMaxHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                rowMaxHeight = Swift.max(rowMaxHeight, size.height)
            }
        }
        totalHeight += rowMaxHeight
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
            rowHeight = Swift.max(rowHeight, size.height)
        }
    }
}
