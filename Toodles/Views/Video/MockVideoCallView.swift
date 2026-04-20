import SwiftUI

struct MockVideoCallView: View {
    let matchName: String
    var onEnd: () -> Void

    @State private var remaining: Int = 60
    @State private var muted: Bool = false
    @State private var showFeedback = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var liked: Bool = false
    @State private var disliked: Bool = false
    @State private var reported: Bool = false

    // Subtitle shown under the peer's name — makes the "mock stranger" feel like a real CSUF match.
    // Swap this out per test account as you record different takes.
    private var matchSubtitle: String { "CSU Fullerton · Senior · Computer Science" }

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
                // Top bar — match name + report + timer
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

                    // Small report affordance (safety escape hatch). Intentionally subtle —
                    // not a primary control, but always one tap away per the PDF's safety claims.
                    Button {
                        reported = true
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

                // Center — peer card
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ToodlesTheme.bodyTop, ToodlesTheme.headerBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: .blue.opacity(0.4), radius: 20, y: 8)

                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    VStack(spacing: 4) {
                        Text(matchName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Text(matchSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

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
                // No hang-up button: per the product thesis, the 60-second timer is the only
                // way the call ends normally. Safety is served by the Report flag in the top bar.
                HStack(spacing: 16) {
                    callButton(
                        icon: muted ? "mic.slash.fill" : "mic.fill",
                        color: muted ? .red : Color(white: 0.25),
                        size: 54
                    ) {
                        muted.toggle()
                    }

                    // Like — heart. Pink when active. Private signal; the peer does not see.
                    Button {
                        liked = true
                        if disliked { disliked = false }
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

                    // Dislike — X. Neutral gray, not red. Private signal.
                    Button {
                        disliked = true
                        if liked { liked = false }
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
            PostSessionFeedbackView(matchName: matchName, onDone: { onEnd() })
        }
    }

    // MARK: - Helpers

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
