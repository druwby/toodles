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

    /// Deterministic first pick (Emma) for demo rehearsals — keeps the narrative
    /// consistent with the Matches tab. Random picks thereafter.
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

    enum Phase { case checkingTrust, matchmaking, blocked }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                switch phase {
                case .checkingTrust:
                    ProgressView().tint(.white).scaleEffect(2)
                    Text("Checking trust score...")
                        .foregroundStyle(.white).font(.title3)
                case .matchmaking:
                    ProgressView().tint(.white).scaleEffect(2)
                    Text("Looking for a match...")
                        .foregroundStyle(.white).font(.title3)
                case .blocked:
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60)).foregroundStyle(.red)
                    Text("Account Suspended")
                        .foregroundStyle(.white).font(.title2.bold())
                    Text("Your trust score is too low to chat.")
                        .foregroundStyle(.white.opacity(0.75))
                    Button("Go Back") { isPresented = false }
                        .buttonStyle(.borderedProminent).tint(.orange)
                }
                Spacer()
                if phase != .blocked {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 40)
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

    private func runFlow() async {
        // Trust Gate — client side, matches the PDF Figure 3 sequence.
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let trust = userViewModel.currentUser?.trustScore ?? 100
        if trust < 50 {
            await MainActor.run { phase = .blocked }
            return
        }
        await MainActor.run { phase = .matchmaking }
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        await MainActor.run { showCall = true }
    }
}
