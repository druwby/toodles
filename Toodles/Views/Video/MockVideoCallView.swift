import SwiftUI

struct MockVideoCallView: View {
    let matchName: String
    var onEnd: () -> Void

    @State private var remaining: Int = 60
    @State private var muted: Bool = false
    @State private var showFeedback = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dark gradient background simulating a video call
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
                // Top bar — match name + timer
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                        Text(matchName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
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

                // Center — "remote user" large card (Tinder-style)
                VStack(spacing: 24) {
                    ZStack {
                        // Animated pulse ring
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

                    VStack(spacing: 6) {
                        Text(matchName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                                .foregroundStyle(.green)
                                .symbolEffect(.variableColor.iterative)
                            Text("Connected")
                                .foregroundStyle(.green)
                                .font(.subheadline.bold())
                        }
                    }
                }

                Spacer()

                // "Your video" small PIP in bottom-right
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
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
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("You")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 20)
                }

                // Bottom controls
                HStack(spacing: 28) {
                    // Mute button
                    callButton(
                        icon: muted ? "mic.slash.fill" : "mic.fill",
                        color: muted ? .red : Color(white: 0.25),
                        size: 60
                    ) {
                        muted.toggle()
                    }

                    // End call button (larger, red)
                    callButton(
                        icon: "phone.down.fill",
                        color: .red,
                        size: 72
                    ) {
                        hangup()
                    }

                    // Camera flip button
                    callButton(
                        icon: "camera.rotate.fill",
                        color: Color(white: 0.25),
                        size: 60
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
                if remaining == 0 { hangup() }
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

    private func hangup() {
        showFeedback = true
    }
}
