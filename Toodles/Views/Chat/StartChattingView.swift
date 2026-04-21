import SwiftUI

/// The demo peer pool. Mirrors the girls in `MatchesViewModel.demoMatches`
/// so the matching flow, post-session feedback, and Matches/Chats tabs all
/// share the same characters — continuity across the demo narrative.
struct DemoPeer {
    let name: String
    let subtitle: String
    let photoUrl: String
}

enum DemoPeerPool {
    static let all: [DemoPeer] = [
        DemoPeer(name: "Emma Chen",         subtitle: "Junior · Nursing",        photoUrl: "https://randomuser.me/api/portraits/women/44.jpg"),
        DemoPeer(name: "Sophia Rodriguez",  subtitle: "Sophomore · Business",    photoUrl: "https://randomuser.me/api/portraits/women/68.jpg"),
        DemoPeer(name: "Olivia Kim",        subtitle: "Senior · Art History",    photoUrl: "https://randomuser.me/api/portraits/women/22.jpg"),
        DemoPeer(name: "Mia Patel",         subtitle: "Senior · Biology",        photoUrl: "https://randomuser.me/api/portraits/women/90.jpg"),
    ]

    static func pick(session index: Int = 0) -> DemoPeer {
        index == 0 ? all[0] : all.randomElement() ?? all[0]
    }
}

struct StartChattingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var phase: Phase = .checkingTrust
    @State private var showCall = false
    @State private var peer: DemoPeer = DemoPeerPool.pick()

    // Animation state
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring3Scale: CGFloat = 1.0
    @State private var foundPulse: CGFloat = 1.0

    enum Phase { case checkingTrust, matchmaking, matchFound, blocked }

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .soft)

            VStack(spacing: 32) {
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
                        Text("Cancel")
                            .font(.body.bold())
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 44)
                }
            }
        }
        .task { await runFlow() }
        .fullScreenCover(isPresented: $showCall) {
            MockVideoCallView(
                matchName: peer.name,
                matchSubtitle: peer.subtitle,
                matchPhotoUrl: peer.photoUrl,
                onEnd: {
                    showCall = false
                    isPresented = false
                }
            )
        }
    }

    // MARK: - Scenes

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
                // Three concentric radar-ping rings expanding out of the center
                radarRing(scale: ring1Scale, delay: 0)
                radarRing(scale: ring2Scale, delay: 0.6)
                radarRing(scale: ring3Scale, delay: 1.2)

                // Center user glyph
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

            Text("Looking for a match…")
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

    // MARK: - Radar ring helper

    private func radarRing(scale: CGFloat, delay: Double) -> some View {
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

    private func runFlow() async {
        // Start ring animations (only takes effect in matchmaking state)
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
            ring1Scale = 2.6
        }
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(0.6)) {
            ring2Scale = 2.6
        }
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(1.2)) {
            ring3Scale = 2.6
        }

        // Trust Gate — ~1.5 sec
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let trust = userViewModel.currentUser?.trustScore ?? 100
        if trust < 50 {
            await MainActor.run { phase = .blocked }
            return
        }

        // Matchmaking — ~2.5 sec
        await MainActor.run {
            withAnimation(.easeInOut) { phase = .matchmaking }
        }
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        // Match found — brief flourish before opening the call
        await MainActor.run {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                phase = .matchFound
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                foundPulse = 1.12
            }
        }
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        await MainActor.run { showCall = true }
    }
}
