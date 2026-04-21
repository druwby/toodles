import SwiftUI

struct MockVideoCallView: View {
    let matchName: String
    let matchSubtitle: String?
    let matchPhotoUrl: String?
    var onEnd: () -> Void

    @State private var remaining: Int = 60
    @State private var muted: Bool = false
    @State private var showFeedback = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var liked: Bool = false
    @State private var disliked: Bool = false
    @State private var reported: Bool = false

    // Default init keeps back-compat with any caller that hasn't passed subtitle/photo.
    init(
        matchName: String,
        matchSubtitle: String? = nil,
        matchPhotoUrl: String? = nil,
        onEnd: @escaping () -> Void
    ) {
        self.matchName = matchName
        self.matchSubtitle = matchSubtitle
        self.matchPhotoUrl = matchPhotoUrl
        self.onEnd = onEnd
    }

    // Brand-aligned Like color. Toodles is blue; the heart reads in pink so it's
    // unambiguously "like" and separates from the blue peer avatar.
    private let likePink = Color(red: 0.96, green: 0.35, blue: 0.55)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.14),
                    Color(red: 0.12, green: 0.10, blue: 0.22),
                    Color(red: 0.06, green: 0.06, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                        Text(matchName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {
                        reported = true
                        // Report also exits the call — you don't keep chatting
                        // with someone you're reporting.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            endCall()
                        }
                    } label: {
                        Image(systemName: reported ? "flag.fill" : "flag")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(reported ? .orange : .white.opacity(0.75))
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Text(timerString)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(remaining <= 10 ? .red : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()

                // Center — peer card. Shows the peer's photo (when provided) inside
                // a pulsing ring, so the mock call feels like a real peer-video tile.
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)

                        peerAvatar
                            .frame(width: 170, height: 170)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 3)
                            )
                            .shadow(color: .blue.opacity(0.4), radius: 20, y: 8)
                    }

                    VStack(spacing: 4) {
                        Text(matchName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        if let sub = matchSubtitle {
                            Text(sub)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                                .foregroundStyle(.green)
                                .symbolEffect(.variableColor.iterative)
                            Text("Connected")
                                .foregroundStyle(.green)
                                .font(.subheadline.bold())
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()

                // Self-view PIP
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 140)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.55))
                                Text("You")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.trailing, 20)
                }

                // Bottom controls — mic / Like / Dislike / camera-flip
                // No hang-up: the 60-second timer is the only normal exit.
                HStack(spacing: 16) {
                    callButton(
                        icon: muted ? "mic.slash.fill" : "mic.fill",
                        color: muted ? .red : Color(white: 0.25),
                        size: 54
                    ) {
                        muted.toggle()
                    }

                    Button {
                        liked = true
                        if disliked { disliked = false }
                        // End the call immediately on Like — the user has decided,
                        // the rest of the 60 seconds adds nothing. Carries the
                        // choice into post-session so the feedback screen starts
                        // on Like → Match Celebration.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            endCall()
                        }
                    } label: {
                        Image(systemName: liked ? "heart.fill" : "heart")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(liked ? likePink : Color(white: 0.25))
                            .clipShape(Circle())
                            .shadow(color: (liked ? likePink : Color.clear).opacity(0.5), radius: 10, y: 4)
                            .scaleEffect(liked ? 1.08 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: liked)
                    }

                    Button {
                        disliked = true
                        if liked { liked = false }
                        // End the call immediately on Dislike — don't force the
                        // user to watch a timer they've already decided to exit.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            endCall()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(disliked ? Color(white: 0.40) : Color(white: 0.20))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(disliked ? 0.5 : 0.1), lineWidth: 1)
                            )
                            .scaleEffect(disliked ? 1.08 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: disliked)
                    }

                    callButton(
                        icon: "camera.rotate.fill",
                        color: Color(white: 0.25),
                        size: 54
                    ) {
                        // No-op in mock
                    }
                }
                .padding(.bottom, 50)
                .padding(.top, 20)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if remaining > 0 {
                remaining -= 1
                if remaining == 0 { endCall() }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
            }
        }
        .fullScreenCover(isPresented: $showFeedback) {
            PostSessionFeedbackView(
                matchName: matchName,
                matchSubtitle: matchSubtitle,
                matchPhotoUrl: matchPhotoUrl,
                presetStatus: preferredStatusFromCallControls,
                onDone: { onEnd() }
            )
        }
    }

    // MARK: - Helpers

    /// Pass the user's mid-call Like/Dislike/Report tap through to the feedback
    /// screen so they don't have to confirm the same decision twice. Matches
    /// the "private signal" story in the Scene 6 voice-over.
    private var preferredStatusFromCallControls: String? {
        if reported { return "reported" }
        if liked    { return "matched" }
        if disliked { return "rejected" }
        return nil
    }

    private var peerAvatar: some View {
        Group {
            if let urlStr = matchPhotoUrl,
               !urlStr.isEmpty,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        avatarFallback
                    }
                }
            } else {
                avatarFallback
            }
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ToodlesTheme.bodyTop, ToodlesTheme.headerBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "person.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var timerString: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%d:%02d", m, s)
    }

    private func callButton(icon: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.5), radius: 8, y: 4)
        }
    }

    private func endCall() {
        showFeedback = true
    }
}
