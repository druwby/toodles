import SwiftUI

struct PostSessionFeedbackView: View {
    let matchName: String
    let matchSubtitle: String?
    let matchPhotoUrl: String?
    /// Carried from mid-call — pre-highlights the matching button so the user
    /// doesn't have to re-rate after tapping heart/X/flag in the call view.
    let presetStatus: String?
    /// True if the user taps Like/Pass/Report and wants to continue matching
    /// with new peers. False if they explicitly tap End for now. The value
    /// bubbles up to StartChattingView which either loops (true) or dismisses
    /// the entire matchmaking flow (false).
    var onDone: (Bool) -> Void

    @State private var isSaving = false
    @State private var selection: String?
    @State private var showCelebration = false

    init(
        matchName: String,
        matchSubtitle: String? = nil,
        matchPhotoUrl: String? = nil,
        presetStatus: String? = nil,
        onDone: @escaping (Bool) -> Void
    ) {
        self.matchName = matchName
        self.matchSubtitle = matchSubtitle
        self.matchPhotoUrl = matchPhotoUrl
        self.presetStatus = presetStatus
        self.onDone = onDone
    }

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .soft)

            VStack(spacing: 24) {
                Spacer(minLength: 8)

                // Peer card — photo, name, subtitle
                VStack(spacing: 12) {
                    PersonAvatar(name: matchName, photoUrl: matchPhotoUrl, size: 150)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.55), lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 14, y: 6)

                    Text(matchName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    if let sub = matchSubtitle {
                        Text(sub)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                VStack(spacing: 4) {
                    Text("How was your chat?")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("We'll line up your next match right after.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

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

                // Explicit "end the session" escape. Without this the loop is
                // infinite — Tinder-style, which is the behaviour we want by
                // default, but the user still needs a clear exit.
                Button {
                    submit(status: "ended", wantsNext: false)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("End for now")
                    }
                    .font(.callout.bold())
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }

                Text("Your rating is private. The other person can't see it.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
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
                onContinue: { wantsNext in
                    showCelebration = false
                    // Give the celebration's dismiss animation a beat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDone(wantsNext)
                    }
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
                selected ? accent : Color.white.opacity(0.18)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(selected ? Color.white : Color.white.opacity(0.25), lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? accent.opacity(0.55) : .clear, radius: 12, y: 6)
            .scaleEffect(selected ? 1.06 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
    }

    private func tap(status: String) {
        selection = status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            submit(status: status, wantsNext: true)
        }
    }

    private func submit(status: String, wantsNext: Bool) {
        guard !isSaving else { return }
        isSaving = true

        // Best-effort Firestore write — don't block the next-match transition
        // on the network round-trip. Scene 7 stays snappy on Appetize.
        if let uid = AuthManager.shared.currentUID, status != "ended" {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isSaving = false
            if status == "matched" {
                // Celebration handles its own wantsNext via its own buttons.
                showCelebration = true
            } else {
                onDone(wantsNext)
            }
        }
    }
}
