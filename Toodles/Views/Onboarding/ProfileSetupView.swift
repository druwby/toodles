import SwiftUI
import PhotosUI

/// Hard-gate shown immediately after first sign-up (or on any login where the
/// user hasn't completed the Hinge/Tinder-style onboarding). Collects photo,
/// first/last name, bio (optional), interests (optional), gender identity,
/// and match preference — all required before the user can reach the main
/// tabs. This is the page that makes Toodles a real dating app instead of a
/// chat roulette.
struct ProfileSetupView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""
    @State private var selectedInterests: Set<String> = []
    @State private var selectedGender: Gender?
    @State private var selectedShowMe: ShowMe?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private static let maxInterests = 5

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

    private var genderFilled: Bool { selectedGender != nil }
    private var showMeFilled: Bool { selectedShowMe != nil }

    private var canContinue: Bool {
        photoIsSet && firstNameFilled && lastNameFilled && genderFilled && showMeFilled && !isSaving
    }

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .heavy)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                            .padding(.top, 42)

                        photoPicker
                            .padding(.top, 4)

                        Text("Tap to add a photo of yourself")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))

                        formCard

                        genderCard

                        showMeCard

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

                requirementsStrip
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
                .font(.system(size: 44))
                .foregroundStyle(.white)
            Text("One last thing")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
            Text("Toodles only shows you to other verified CSUF students. A few quick things first:")
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
                    .frame(width: 150, height: 150)

                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } else if let url = userViewModel.currentUser?.profilePhotoUrl,
                          !url.isEmpty,
                          let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Circle()
                    .fill(ToodlesTheme.accent)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: pickedImage != nil ? "checkmark" : "plus")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    )
                    .offset(x: -2, y: -2)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 5)
        }
    }

    // MARK: - Name + bio

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
                // iOS 17 multi-line TextField — doesn't steal scroll gestures
                // from the outer ScrollView the way TextEditor does.
                TextField(
                    "",
                    text: $bio,
                    prompt: Text("Tell us a bit about yourself…").foregroundStyle(.gray),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .foregroundStyle(.black)
                .tint(.black)
                .padding(10)
                .background(Color(white: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("\(bio.count)/200 characters")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Gender card

    private var genderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("I am a")
                .font(.caption.bold())
                .foregroundStyle(.black)

            HStack(spacing: 8) {
                ForEach(Gender.allCases) { g in
                    pillButton(
                        title: g.displayName,
                        selected: selectedGender == g
                    ) {
                        selectedGender = g
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Show me card

    private var showMeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Show me")
                .font(.caption.bold())
                .foregroundStyle(.black)

            HStack(spacing: 8) {
                ForEach(ShowMe.allCases) { s in
                    pillButton(
                        title: s.displayName,
                        selected: selectedShowMe == s
                    ) {
                        selectedShowMe = s
                    }
                }
            }

            Text("We'll only match you with people who fit.")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func pillButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.bold())
                .foregroundStyle(selected ? .white : ToodlesTheme.avatarText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    selected
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
                        // Unselected: a darker chip so the pill is visible on
                        // the white card. chipBlue is nearly-white and was
                        // blending into the card surface, making unselected
                        // pills look "missing".
                        : AnyShapeStyle(Color(red: 0.90, green: 0.92, blue: 0.97))
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            selected
                                ? Color.white.opacity(0.6)
                                : ToodlesTheme.avatarText.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .scaleEffect(selected ? 1.03 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
    }

    // MARK: - Interest selection

    private var interestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
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

    // MARK: - Requirements strip

    private var requirementsStrip: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            requirementCheck(met: photoIsSet,      label: "Photo")
            requirementCheck(met: firstNameFilled, label: "First")
            requirementCheck(met: lastNameFilled,  label: "Last")
            requirementCheck(met: genderFilled,    label: "Gender")
            requirementCheck(met: showMeFilled,    label: "Show me")
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
    }

    private func requirementCheck(met: Bool, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption2.bold())
                .foregroundStyle(met ? .green : .white.opacity(0.55))
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(met ? .green : .white.opacity(0.9))
        }
    }

    // MARK: - Continue bar

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
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                Text("We use this to find you the right matches, never to show others more than you want.")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Hydrate + save

    private func hydrateFromExistingUser() {
        guard let u = userViewModel.currentUser else { return }

        let parts = u.displayName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if firstName.isEmpty, let f = parts.first { firstName = String(f) }
        if lastName.isEmpty,  parts.count > 1 { lastName = String(parts[1]) }
        if bio.isEmpty { bio = u.bio }
        if selectedInterests.isEmpty { selectedInterests = Set(u.interests) }
        if selectedGender == nil { selectedGender = u.gender }
        if selectedShowMe == nil { selectedShowMe = u.showMe }
    }

    private func save() {
        errorMessage = nil

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
        guard let gender = selectedGender else {
            errorMessage = "Please pick your gender."
            return
        }
        guard let showMe = selectedShowMe else {
            errorMessage = "Please pick who you want to see."
            return
        }
        guard let uid = AuthManager.shared.currentUID else {
            errorMessage = "You're not signed in. Try signing in again."
            return
        }

        isSaving = true
        let fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if isSaving {
                isSaving = false
                errorMessage = "Saving is taking a while. Try Continue again."
            }
        }

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
                createdAt: userViewModel.currentUser?.createdAt ?? Date(),
                gender: gender,
                showMe: showMe
            )
            userViewModel.currentUser = updated
            userViewModel.cacheProfile(updated)
        }

        let initialsAvatarUrl: () -> String = {
            let seed = fullName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Toodles+User"
            return "https://api.dicebear.com/9.x/initials/png?seed=\(seed)&backgroundColor=ff6b6b,4dabf7,fa983a,f55a8b&fontWeight=700"
        }

        let persistToFirestore: (String) -> Void = { photoUrl in
            let data: [String: Any] = [
                "display_name":      fullName,
                "first_name":        firstName.trimmingCharacters(in: .whitespaces),
                "last_name":         lastName.trimmingCharacters(in: .whitespaces),
                "bio":               String(bio.prefix(200)),
                "interests":         Array(selectedInterests),
                "profile_photo_url": photoUrl,
                "gender":            gender.rawValue,
                "show_me":           showMe.rawValue
            ]
            FirestoreService.shared.updateUser(uid: uid, data: data) { _ in
                DispatchQueue.main.async {
                    isSaving = false
                    advanceLocally(photoUrl)
                }
            }
        }

        if let img = pickedImage {
            StorageService.shared.uploadProfilePhoto(uid: uid, image: img) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        persistToFirestore(url)
                    case .failure:
                        persistToFirestore(initialsAvatarUrl())
                    }
                }
            }
        } else if let existing = userViewModel.currentUser?.profilePhotoUrl, !existing.isEmpty {
            persistToFirestore(existing)
        } else {
            persistToFirestore(initialsAvatarUrl())
        }
    }

    private var authManagerEmail: String {
        AuthManager.shared.currentEmail ?? ""
    }
}

// MARK: - InterestTag + grid

struct InterestTag: Hashable {
    let name: String
    let emoji: String
}

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
