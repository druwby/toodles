import SwiftUI

struct PostSessionFeedbackView: View {
    let matchName: String
    let matchSubtitle: String?
    let matchPhotoUrl: String?
    /// Partner UID when this session came from a real Firestore pairing.
    /// Nil for demo-pool fallback sessions. Used to direct trust events
    /// (penalty on report, reward for a valid flag) at the right account.
    let partnerUID: String?
    /// Session identifier from the matchmaker. Attached to trust events so
    /// the audit log can be correlated with the session on later review.
    let sessionID: String?
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

    // Transcript state (TDV-84 / Subproject E). Lazy-loads on appear so the
    // feedback buttons render instantly; transcript row fades in when ready.
    @State private var transcript: Transcript?
    @State private var isTranscriptExpanded: Bool = false
    @State private var transcriptError: String?

    init(
        matchName: String,
        matchSubtitle: String? = nil,
        matchPhotoUrl: String? = nil,
        partnerUID: String? = nil,
        sessionID: String? = nil,
        presetStatus: String? = nil,
        onDone: @escaping (Bool) -> Void
    ) {
        self.matchName = matchName
        self.matchSubtitle = matchSubtitle
        self.matchPhotoUrl = matchPhotoUrl
        self.partnerUID = partnerUID
        self.sessionID = sessionID
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

                // Transcript section — collapsible, appears only when loaded.
                if let transcript = transcript {
                    transcriptSection(transcript)
                        .padding(.horizontal, 24)
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
            loadTranscript()
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
            let otherUid = partnerUID ?? "demo_\(matchName.replacingOccurrences(of: " ", with: "_"))"
            FirestoreService.shared.createMatch(userA: uid, userB: otherUid, status: status) { _ in }

            if status == "reported" {
                FirestoreService.shared.createSupportTicket(
                    userId: uid,
                    subject: "Report: \(matchName)",
                    description: "User reported from post-session feedback.",
                    category: "report_user"
                ) { _ in }
            }

            // Trust events (TDV-83). Fire-and-forget — the event write
            // is best-effort; the score will reconcile on next fetch.
            emitTrustEvents(selfUID: uid, status: status)
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

    // MARK: - Transcript

    private func loadTranscript() {
        guard transcript == nil, let sid = sessionID else { return }
        // Use the same icebreaker the session would have shown — seeds the
        // synthetic transcript so it references the actual prompt.
        let icebreaker = IcebreakerService.pick(sessionID: sid)
        let userName = AuthManager.shared.currentEmail?
            .components(separatedBy: "@").first ?? "You"
        Task {
            do {
                let t = try await TranscriptService.transcribe(
                    sessionID: sid,
                    peerName: matchName,
                    userName: userName,
                    icebreakerText: icebreaker.text,
                    audioURL: nil
                )
                await MainActor.run { transcript = t }
            } catch {
                await MainActor.run { transcriptError = error.localizedDescription }
            }
        }
    }

    private func transcriptSection(_ t: Transcript) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isTranscriptExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "text.bubble.fill")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.75))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Transcript")
                                .font(.callout.bold())
                                .foregroundStyle(.white)
                            if t.isSynthetic {
                                Text("DEMO")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow.opacity(0.85))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(t.isSynthetic
                             ? "Preview only — not a live recording."
                             : "Captured via Whisper.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: isTranscriptExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isTranscriptExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(t.turns) { turn in
                        transcriptTurnRow(turn)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func transcriptTurnRow(_ turn: TranscriptTurn) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(turn.speaker == .you ? "You" : matchName.components(separatedBy: " ").first ?? matchName)
                .font(.caption.bold())
                .foregroundStyle(turn.speaker == .you ? Color(red: 0.96, green: 0.35, blue: 0.55) : Color(red: 0.42, green: 0.72, blue: 1.0))
                .frame(width: 54, alignment: .leading)
                .padding(.top, 2)
            Text(turn.text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    /// Emit the trust-score deltas that correspond to this session outcome.
    /// Runs in a detached Task so it doesn't block the UI transition.
    /// Events against the partner are only emitted when we have a real
    /// partner UID (live session), not for demo-pool fallback peers.
    private func emitTrustEvents(selfUID: String, status: String) {
        Task {
            let manager = TrustScoreManager.shared
            switch status {
            case "matched":
                _ = try? await manager.applyEvent(
                    kind: .positiveSessionCompleted,
                    for: selfUID,
                    actor: selfUID,
                    sessionID: sessionID
                )
            case "rejected":
                // A neutral outcome — event is still recorded so the history
                // shows the session happened.
                _ = try? await manager.applyEvent(
                    kind: .neutralSessionCompleted,
                    for: selfUID,
                    actor: selfUID,
                    sessionID: sessionID
                )
            case "reported":
                // Reporter gets a small credit for flagging bad behavior.
                _ = try? await manager.applyEvent(
                    kind: .reportedSomeone,
                    for: selfUID,
                    actor: selfUID,
                    sessionID: sessionID,
                    note: "reported \(matchName)"
                )
                // Reported partner takes a penalty — only if this was a real
                // paired session (we have their UID). Demo-fallback peers
                // are synthetic so we skip.
                if let partnerUID = partnerUID {
                    _ = try? await manager.applyEvent(
                        kind: .reportedBySomeone,
                        for: partnerUID,
                        actor: selfUID,
                        sessionID: sessionID,
                        note: "reported by \(selfUID)"
                    )
                }
            default:
                break
            }
        }
    }
}
