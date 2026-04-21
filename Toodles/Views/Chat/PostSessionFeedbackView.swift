import SwiftUI

struct PostSessionFeedbackView: View {
    let matchName: String
    let matchSubtitle: String?
    let matchPhotoUrl: String?
    /// If set (e.g. the user already tapped Like mid-call), the matching button
    /// is pre-highlighted so the rating state carries over.
    let presetStatus: String?
    var onDone: () -> Void

    @State private var isSaving = false
    @State private var selection: String?
    @State private var showCelebration = false

    init(
        matchName: String,
        matchSubtitle: String? = nil,
        matchPhotoUrl: String? = nil,
        presetStatus: String? = nil,
        onDone: @escaping () -> Void
    ) {
        self.matchName = matchName
        self.matchSubtitle = matchSubtitle
        self.matchPhotoUrl = matchPhotoUrl
        self.presetStatus = presetStatus
        self.onDone = onDone
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 8)

                // Peer card — photo, name, subtitle
                VStack(spacing: 14) {
                    PersonAvatar(name: matchName, photoUrl: matchPhotoUrl, size: 160)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.65), lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)

                    Text(matchName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    if let sub = matchSubtitle {
                        Text(sub)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                Text("How was your chat?")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.95))

                HStack(spacing: 18) {
                    feedbackButton(
                        symbol: "heart.fill",
                        accent: Color(red: 0.96, green: 0.35, blue: 0.55),
                        label: "Like",
                        status: "matched"
                    )
                    feedbackButton(
                        symbol: "xmark",
                        accent: Color(white: 0.4),
                        label: "Pass",
                        status: "rejected"
                    )
                    feedbackButton(
                        symbol: "flag.fill",
                        accent: Color.red.opacity(0.85),
                        label: "Report",
                        status: "reported"
                    )
                }

                if isSaving {
                    ProgressView().tint(.white)
                }

                Spacer()

                Text("Your response is private. The other person can't see it.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }
        }
        .disabled(isSaving)
        .onAppear {
            selection = presetStatus
        }
        .fullScreenCover(isPresented: $showCelebration) {
            MatchCelebrationView(
                matchName: matchName,
                matchPhotoUrl: matchPhotoUrl,
                onContinue: {
                    showCelebration = false
                    onDone()
                }
            )
        }
    }

    private func feedbackButton(symbol: String, accent: Color, label: String, status: String) -> some View {
        let selected = selection == status
        return Button {
            tap(status: status)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .bold))
                Text(label).font(.caption.bold())
            }
            .frame(width: 92, height: 92)
            .foregroundStyle(.white)
            .background(
                selected ? accent : Color.white.opacity(0.22)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? Color.white : Color.white.opacity(0.3), lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? accent.opacity(0.5) : .clear, radius: 12, y: 6)
            .scaleEffect(selected ? 1.06 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
    }

    private func tap(status: String) {
        selection = status
        // Give the button animation a beat to read, then submit.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            submit(status: status)
        }
    }

    private func submit(status: String) {
        guard !isSaving else { return }
        isSaving = true

        // Demo path: no real Firestore write required for the capstone presentation.
        // We still hit Firestore if the user is authenticated, but we don't block
        // the celebration on it. This keeps Scene 7 snappy on Appetize.
        if let uid = AuthManager.shared.currentUID {
            let fakeOtherUid = "demo_\(matchName.replacingOccurrences(of: " ", with: "_"))"
            FirestoreService.shared.createMatch(userA: uid, userB: fakeOtherUid, status: status) { _ in }

            if status == "reported" {
                FirestoreService.shared.createSupportTicket(
                    userId: uid,
                    subject: "Report: \(matchName)",
                    description: "User reported from post-session feedback.",
                    category: "report_user"
                ) { _ in }
            }
        }

        // Reveal the celebration on Like. Pass/Report dismiss directly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isSaving = false
            if status == "matched" {
                showCelebration = true
            } else {
                onDone()
            }
        }
    }
}
