import SwiftUI

/// The demo peer pool. Mixed-gender so the matchmaking "Show me" filter
/// actually has meaningful effect. Each peer's gender is used to decide
/// whether they're shown to the current user. Interests + trustScore +
/// accountAgeDays feed MatchScorer (Subproject B) so the demo flow visibly
/// shows a ranked result, not a static round-robin.
struct DemoPeer: MatchCandidate {
    let name: String
    let subtitle: String
    let photoUrl: String
    let gender: Gender
    let interests: [String]
    let trustScore: Int
    let accountAgeDays: Int

    func sharedInterests(with userInterests: [String]) -> [String] {
        let userSet = Set(userInterests.map { $0.lowercased() })
        return interests.filter { userSet.contains($0.lowercased()) }
    }
}

enum DemoPeerPool {
    static let all: [DemoPeer] = [
        // Women
        DemoPeer(name: "Emma Chen",         subtitle: "Junior · Nursing",        photoUrl: "https://randomuser.me/api/portraits/women/44.jpg", gender: .woman,
                 interests: ["Coffee", "Hiking", "Reading", "Photography"],
                 trustScore: 88, accountAgeDays: 240),
        DemoPeer(name: "Sophia Rodriguez",  subtitle: "Sophomore · Business",    photoUrl: "https://randomuser.me/api/portraits/women/68.jpg", gender: .woman,
                 interests: ["Travel", "Coffee", "Dance", "Cooking"],
                 trustScore: 76, accountAgeDays: 95),
        DemoPeer(name: "Olivia Kim",        subtitle: "Senior · Art History",    photoUrl: "https://randomuser.me/api/portraits/women/22.jpg", gender: .woman,
                 interests: ["Art", "Film", "Photography", "Travel"],
                 trustScore: 92, accountAgeDays: 380),
        DemoPeer(name: "Mia Patel",         subtitle: "Senior · Biology",        photoUrl: "https://randomuser.me/api/portraits/women/90.jpg", gender: .woman,
                 interests: ["Running", "Cooking", "Reading", "Music"],
                 trustScore: 81, accountAgeDays: 200),
        DemoPeer(name: "Hannah Foster",     subtitle: "Junior · Communications", photoUrl: "https://randomuser.me/api/portraits/women/65.jpg", gender: .woman,
                 interests: ["Music", "Film", "Dance", "Travel"],
                 trustScore: 70, accountAgeDays: 45),
        DemoPeer(name: "Riley Park",        subtitle: "Senior · Kinesiology",    photoUrl: "https://randomuser.me/api/portraits/women/17.jpg", gender: .woman,
                 interests: ["Running", "Hiking", "Yoga", "Cooking"],
                 trustScore: 85, accountAgeDays: 310),
        // Men
        DemoPeer(name: "Ethan Ross",        subtitle: "Junior · Physics",        photoUrl: "https://randomuser.me/api/portraits/men/45.jpg",   gender: .man,
                 interests: ["Gaming", "Film", "Coffee", "Reading"],
                 trustScore: 83, accountAgeDays: 170),
        DemoPeer(name: "Lucas Martinez",    subtitle: "Senior · CS",             photoUrl: "https://randomuser.me/api/portraits/men/32.jpg",   gender: .man,
                 interests: ["Gaming", "Music", "Coffee", "Hiking"],
                 trustScore: 90, accountAgeDays: 420),
        DemoPeer(name: "Noah Williams",     subtitle: "Junior · Economics",      photoUrl: "https://randomuser.me/api/portraits/men/64.jpg",   gender: .man,
                 interests: ["Travel", "Running", "Cooking", "Photography"],
                 trustScore: 78, accountAgeDays: 130),
        DemoPeer(name: "Aiden Cho",         subtitle: "Senior · Mechanical Eng", photoUrl: "https://randomuser.me/api/portraits/men/75.jpg",   gender: .man,
                 interests: ["Gaming", "Film", "Art", "Music"],
                 trustScore: 74, accountAgeDays: 60),
    ]

    /// Return the subset of peers that match the user's `Show me` preference.
    static func visibleTo(showMe: ShowMe?) -> [DemoPeer] {
        let filter = showMe ?? .everyone
        let visible = all.filter { filter.matches($0.gender) }
        return visible.isEmpty ? all : visible
    }

    /// Rank visible peers by MatchScorer, highest score first. Ties resolve
    /// deterministically by name so the order is stable across runs.
    static func ranked(for user: User?) -> [DemoPeer] {
        let visible = visibleTo(showMe: user?.showMe)
        guard let user = user else { return visible }
        return visible
            .map { (peer: $0, score: MatchScorer.score(current: user, candidate: $0).total) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.peer.name < rhs.peer.name
            }
            .map(\.peer)
    }

    /// Session-indexed pick from the ranked list. Session 0 gets the best
    /// match; subsequent sessions walk down the ranked list so each call
    /// shows a different (but still score-ordered) peer.
    static func pick(session index: Int, for user: User?) -> DemoPeer {
        let pool = ranked(for: user)
        if pool.isEmpty { return all[0] }
        return pool[index % pool.count]
    }

    /// Legacy round-robin entry point — kept for any caller that doesn't
    /// have a User available yet. New code should prefer `pick(session:for:)`.
    static func pick(session index: Int, showMe: ShowMe?) -> DemoPeer {
        let pool = visibleTo(showMe: showMe)
        return pool[index % pool.count]
    }
}

struct StartChattingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var matchmaker = MatchmakingService()

    @State private var phase: Phase = .checkingTrust
    @State private var showCall = false
    @State private var sessionIndex: Int = 0
    @State private var peer: DemoPeer = DemoPeerPool.all[0]
    /// Set when a real Firestore-backed session pairs us with another live
    /// user. When non-nil, the call view uses this instead of `peer` so the
    /// remote participant's name/photo/sessionID come from Firestore. When
    /// nil, we fell back to `peer` from DemoPeerPool.
    @State private var activeSession: MatchSession?
    /// Stable identifier for the current call session. Regenerated per session
    /// so the icebreaker picker returns a fresh prompt each time.
    @State private var currentSessionID: String = UUID().uuidString

    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring3Scale: CGFloat = 1.0
    @State private var foundPulse: CGFloat = 1.0
    @State private var showRecovery: Bool = false

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
                matchName: callName,
                matchSubtitle: callSubtitle,
                matchPhotoUrl: callPhotoUrl,
                sessionID: callSessionID,
                sharedInterests: callSharedInterests,
                partnerUID: activeSession?.partnerUID,
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
        .onDisappear {
            // If the user taps Cancel or End-session mid-matchmaking, don't
            // leave our queue entry hanging in Firestore. Fire-and-forget —
            // the service is @MainActor-isolated so the Task is cheap.
            Task { await matchmaker.cancelSearch() }
        }
        .fullScreenCover(isPresented: $showRecovery, onDismiss: {
            // User came back from the recovery flow. If their score now
            // clears the threshold, re-run the trust check and let them in.
            if (userViewModel.currentUser?.trustScore ?? 0) >= 50 && phase == .blocked {
                sessionIndex += 1  // re-trigger .task(id:)
            }
        }) {
            NavigationStack {
                TrustRecoveryView()
                    .environmentObject(userViewModel)
            }
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

    // MARK: - Display derivation
    //
    // The call view needs name / photo / subtitle / sharedInterests / sessionID.
    // These can come from either a real MatchSession (live Firestore pairing)
    // or a DemoPeer (single-user fallback). `callName` et al. centralize the
    // choice so the matchFoundScene and MockVideoCallView stay agnostic.

    private var callName: String {
        activeSession?.partnerName ?? peer.name
    }
    private var callPhotoUrl: String? {
        activeSession?.partnerPhotoUrl ?? peer.photoUrl
    }
    private var callSubtitle: String? {
        activeSession?.partnerSubtitle ?? peer.subtitle
    }
    private var callSessionID: String {
        activeSession?.sessionID ?? currentSessionID
    }
    private var callSharedInterests: [String] {
        if let s = activeSession { return s.sharedInterests }
        return peer.sharedInterests(with: userViewModel.currentUser?.interests ?? [])
    }
    private var isLiveMatch: Bool { activeSession != nil }

    private var matchFoundScene: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(foundPulse)

                PersonAvatar(name: callName, photoUrl: callPhotoUrl, size: 170)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
            }

            HStack(spacing: 6) {
                if isLiveMatch {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                Text(isLiveMatch ? "Live match found!" : "Match found!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }

            Text("Connecting you with \(callName)…")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.85))

            // Surface the shared interests so the user can see *why* this
            // peer was picked — gives the matching algorithm a visible
            // presence in the demo flow.
            if !callSharedInterests.isEmpty {
                sharedInterestStrip(callSharedInterests)
            }
        }
    }

    private func sharedInterestStrip(_ interests: [String]) -> some View {
        VStack(spacing: 8) {
            Text("You both like")
                .font(.caption2.bold())
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.65))

            HStack(spacing: 6) {
                ForEach(interests.prefix(4), id: \.self) { tag in
                    Text(tag)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.top, 4)
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

            Text("Paused from matchmaking")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Your trust score is too low to start a chat right now. Complete a few quick tasks to get back to matching.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Primary action — open the recovery flow. Turns the blocked
            // state from a dead end into a user-visible path forward.
            Button {
                showRecovery = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward.circle.fill")
                    Text("Rebuild your score")
                }
                .font(.body.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
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
                .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.30).opacity(0.45), radius: 12, y: 6)
            }
            .padding(.top, 12)

            Button {
                isPresented = false
            } label: {
                Text("Not now")
                    .font(.callout.bold())
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
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
        // Incrementing sessionIndex re-triggers .task(id:) -> runFlow() ->
        // matchmaking -> call. Clear any prior live session so the next pass
        // re-enters the queue cleanly; peer + sessionID are re-derived inside
        // runFlow() once matchmaker either pairs us or times out.
        sessionIndex += 1
        activeSession = nil
    }

    private func runFlow() async {
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

        // Try a real Firestore-backed live match first. Fall back to the
        // demo pool if we can't reach Firebase (no profile loaded yet,
        // GoogleService-Info.plist missing) or if the 15-second scan
        // returns no compatible peers.
        let session = await findLiveMatch()
        await MainActor.run {
            if let session = session {
                activeSession = session
            } else {
                activeSession = nil
                peer = DemoPeerPool.pick(session: sessionIndex, for: userViewModel.currentUser)
                currentSessionID = UUID().uuidString
            }
        }

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

    /// Enter the Firestore queue and await a real pairing. Returns nil on
    /// timeout, missing auth, or any Firestore error — callers fall back to
    /// DemoPeerPool in that case so single-user testing still works.
    private func findLiveMatch() async -> MatchSession? {
        guard let me = userViewModel.currentUser,
              me.id != nil,
              AuthManager.shared.isSignedIn else {
            // Brief delay so the matchmaking animation doesn't snap to
            // matchFound instantly — preserves the "finding someone" feel
            // even in the fallback path.
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            return nil
        }

        await matchmaker.startSearching(as: me)

        // Poll the service for a terminal state. The service enforces its own
        // timeout internally (MatchmakingService.scanTimeoutSeconds), so this
        // loop only exists to surface the result to SwiftUI.
        let hardCap = Date().addingTimeInterval(MatchmakingService.scanTimeoutSeconds + 3)
        while matchmaker.isSearching, Date() < hardCap {
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        if case .matched(let session) = matchmaker.status {
            return session
        }
        await matchmaker.cancelSearch()
        return nil
    }
}
