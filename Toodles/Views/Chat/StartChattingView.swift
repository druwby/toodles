import SwiftUI

/// The demo peer pool. Mixed-gender so the matchmaking "Show me" filter
/// actually has meaningful effect. Each peer's gender is used to decide
/// whether they're shown to the current user.
struct DemoPeer {
    let name: String
    let subtitle: String
    let photoUrl: String
    let gender: Gender
}

enum DemoPeerPool {
    static let all: [DemoPeer] = [
        // Women
        DemoPeer(name: "Emma Chen",         subtitle: "Junior · Nursing",        photoUrl: "https://randomuser.me/api/portraits/women/44.jpg", gender: .woman),
        DemoPeer(name: "Sophia Rodriguez",  subtitle: "Sophomore · Business",    photoUrl: "https://randomuser.me/api/portraits/women/68.jpg", gender: .woman),
        DemoPeer(name: "Olivia Kim",        subtitle: "Senior · Art History",    photoUrl: "https://randomuser.me/api/portraits/women/22.jpg", gender: .woman),
        DemoPeer(name: "Mia Patel",         subtitle: "Senior · Biology",        photoUrl: "https://randomuser.me/api/portraits/women/90.jpg", gender: .woman),
        DemoPeer(name: "Hannah Foster",     subtitle: "Junior · Communications", photoUrl: "https://randomuser.me/api/portraits/women/65.jpg", gender: .woman),
        DemoPeer(name: "Riley Park",        subtitle: "Senior · Kinesiology",    photoUrl: "https://randomuser.me/api/portraits/women/17.jpg", gender: .woman),
        // Men
        DemoPeer(name: "Ethan Ross",        subtitle: "Junior · Physics",        photoUrl: "https://randomuser.me/api/portraits/men/45.jpg",   gender: .man),
        DemoPeer(name: "Lucas Martinez",    subtitle: "Senior · CS",             photoUrl: "https://randomuser.me/api/portraits/men/32.jpg",   gender: .man),
        DemoPeer(name: "Noah Williams",     subtitle: "Junior · Economics",      photoUrl: "https://randomuser.me/api/portraits/men/64.jpg",   gender: .man),
        DemoPeer(name: "Aiden Cho",         subtitle: "Senior · Mechanical Eng", photoUrl: "https://randomuser.me/api/portraits/men/75.jpg",   gender: .man),
    ]

    /// Return the subset of peers that match the user's `Show me` preference.
    static func visibleTo(showMe: ShowMe?) -> [DemoPeer] {
        let filter = showMe ?? .everyone
        let visible = all.filter { filter.matches($0.gender) }
        return visible.isEmpty ? all : visible
    }

    /// Deterministic round-robin through the visible peers for the given user
    /// preference. First session is the first peer, which — for a "show me
    /// women" user — is Emma, matching the pre-seeded Matches tab.
    static func pick(session index: Int, showMe: ShowMe?) -> DemoPeer {
        let pool = visibleTo(showMe: showMe)
        return pool[index % pool.count]
    }
}

struct StartChattingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var phase: Phase = .checkingTrust
    @State private var showCall = false
    @State private var sessionIndex: Int = 0
    @State private var peer: DemoPeer = DemoPeerPool.all[0]

    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring3Scale: CGFloat = 1.0
    @State private var foundPulse: CGFloat = 1.0

    enum Phase { case checkingTrust, matchmaking, matchFound, blocked }

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .soft)

            VStack(spacing: 0) {
                // Session counter chip — shows this is a flowing sequence, not one-shot
                if sessionIndex > 0 && phase != .blocked {
                    sessionCounterChip
                        .padding(.top, 28)
                }

                Spacer()

                switch phase {
                case .checkingTrust:
                    trustCheckScene
                case .matchmaking:
                    matchmakingScene
                case .matchFound:
                    matchFoundScene
                case .blocked:
                    blockedScene
                }

                Spacer()

                if phase != .blocked {
                    Button {
                        isPresented = false
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                            Text(sessionIndex == 0 ? "Cancel" : "End session")
                        }
                        .font(.body.bold())
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 44)
                }
            }
        }
        // `.task(id:)` re-runs whenever sessionIndex changes so the matching
        // animation replays between matches — the "finding your next person"
        // transition is just this same flow running again.
        .task(id: sessionIndex) {
            await runFlow()
        }
        .fullScreenCover(isPresented: $showCall) {
            MockVideoCallView(
                matchName: peer.name,
                matchSubtitle: peer.subtitle,
                matchPhotoUrl: peer.photoUrl,
                onEnd: { wantsNext in
                    showCall = false
                    if wantsNext {
                        // Give the cover's dismiss animation a beat, then loop.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startNextMatch()
                        }
                    } else {
                        isPresented = false
                    }
                }
            )
        }
    }

    // MARK: - Scenes

    private var sessionCounterChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.caption2.bold())
            Text("Chat \(sessionIndex + 1) of your session")
                .font(.caption.bold())
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var trustCheckScene: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 2)
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.42, green: 0.72, blue: 1.0), Color(red: 0.25, green: 0.45, blue: 0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 118, height: 118)
                    .shadow(color: Color.blue.opacity(0.5), radius: 20, y: 8)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Verifying your trust score…")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Running the Trust Gate via Cloud Functions")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            ProgressView()
                .tint(.white)
                .padding(.top, 8)
        }
    }

    private var matchmakingScene: some View {
        VStack(spacing: 20) {
            ZStack {
                radarRing(scale: ring1Scale)
                radarRing(scale: ring2Scale)
                radarRing(scale: ring3Scale)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.42, blue: 0.58),
                                Color(red: 0.98, green: 0.58, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.40).opacity(0.55), radius: 20, y: 8)

                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 240, height: 240)

            Text(sessionIndex == 0 ? "Looking for a match…" : "Finding your next match…")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Finding a verified CSUF student nearby")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var matchFoundScene: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(foundPulse)

                PersonAvatar(name: peer.name, photoUrl: peer.photoUrl, size: 170)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
            }

            Text("Match found!")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Connecting you with \(peer.name)…")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var blockedScene: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 140, height: 140)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.red)
            }

            Text("Account suspended")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Your trust score is too low to chat right now.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                isPresented = false
            } label: {
                Text("Go back")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(ToodlesTheme.accent)
                    .clipShape(Capsule())
            }
            .padding(.top, 12)
        }
    }

    private func radarRing(scale: CGFloat) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.42, blue: 0.58).opacity(0.6 * (2 - scale)),
                        Color(red: 0.98, green: 0.58, blue: 0.12).opacity(0.6 * (2 - scale))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: 90, height: 90)
            .scaleEffect(scale)
    }

    // MARK: - Flow

    private func startNextMatch() {
        // Round-robin through the peers that match the user's Show me filter.
        // Incrementing sessionIndex re-triggers .task(id:) -> runFlow() ->
        // matchmaking -> call.
        sessionIndex += 1
        peer = DemoPeerPool.pick(session: sessionIndex, showMe: userViewModel.currentUser?.showMe)
    }

    private func runFlow() async {
        // Make sure the peer reflects the user's current "Show me" preference
        // (important on the very first run — we defaulted to all[0] before
        // the view had access to userViewModel).
        if sessionIndex == 0 {
            await MainActor.run {
                peer = DemoPeerPool.pick(session: 0, showMe: userViewModel.currentUser?.showMe)
            }
        }

        // Radar animations — start fresh for every session.
        ring1Scale = 1.0; ring2Scale = 1.0; ring3Scale = 1.0
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
            ring1Scale = 2.6
        }
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(0.6)) {
            ring2Scale = 2.6
        }
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(1.2)) {
            ring3Scale = 2.6
        }

        // Trust check only on the first session — subsequent matches skip
        // straight to matchmaking since we already know the user passed.
        if sessionIndex == 0 {
            await MainActor.run { phase = .checkingTrust }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            let trust = userViewModel.currentUser?.trustScore ?? 100
            if trust < 50 {
                await MainActor.run { phase = .blocked }
                return
            }
        }

        await MainActor.run {
            withAnimation { phase = .matchmaking }
        }
        try? await Task.sleep(nanoseconds: 2_200_000_000)

        await MainActor.run {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                phase = .matchFound
            }
            foundPulse = 1.0
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                foundPulse = 1.12
            }
        }
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        await MainActor.run { showCall = true }
    }
}
