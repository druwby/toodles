import SwiftUI

/// Shown immediately after a user taps Like on the PostSessionFeedbackView.
/// In production this would fire only on a mutual-like; for the demo it fires
/// every time so faculty see the moment. Keeps the narrative of "your chat
/// turned into a connection" visible in the recording.
struct MatchCelebrationView: View {
    let matchName: String
    let matchPhotoUrl: String?
    var onContinue: () -> Void

    @State private var animate = false
    @State private var floatHearts = false

    private let coral = Color(red: 0.96, green: 0.35, blue: 0.55)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    coral.opacity(0.85),
                    Color(red: 0.95, green: 0.45, blue: 0.35),
                    Color(red: 0.55, green: 0.3, blue: 0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating hearts decoration
            heartsLayer
                .allowsHitTesting(false)

            VStack(spacing: 28) {
                Spacer()

                Text("It's a Match!")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                    .scaleEffect(animate ? 1.0 : 0.6)
                    .opacity(animate ? 1.0 : 0.0)

                Text("You and \(matchName) both liked each other")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animate ? 1.0 : 0.0)

                // Two photo pair
                HStack(spacing: -28) {
                    circleAvatar(photoUrl: nil, initials: "You", tint: Color.white.opacity(0.35))
                        .rotationEffect(.degrees(animate ? -10 : -60))
                        .offset(x: animate ? 0 : -120)
                    circleAvatar(photoUrl: matchPhotoUrl, initials: String(matchName.prefix(2)).uppercased(), tint: Color.white.opacity(0.35))
                        .rotationEffect(.degrees(animate ? 10 : 60))
                        .offset(x: animate ? 0 : 120)
                }
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        onContinue()
                    } label: {
                        Text("Send a message")
                            .font(.title3.bold())
                            .foregroundStyle(coral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    Button {
                        onContinue()
                    } label: {
                        Text("Keep swiping")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(animate ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1)) {
                animate = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
                floatHearts = true
            }
        }
    }

    // MARK: - Photo avatar (reuses PersonAvatar but at large size with a pink ring)

    private func circleAvatar(photoUrl: String?, initials: String, tint: Color) -> some View {
        ZStack {
            PersonAvatar(name: initials, photoUrl: photoUrl, size: 150)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 5)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    // MARK: - Floating hearts background

    private var heartsLayer: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "heart.fill")
                        .font(.system(size: CGFloat(18 + (i * 3) % 20)))
                        .foregroundStyle(Color.white.opacity(0.18))
                        .position(
                            x: CGFloat((i * 73) % Int(geo.size.width)),
                            y: floatHearts
                                ? -80
                                : geo.size.height + CGFloat((i * 47) % 150)
                        )
                        .animation(
                            .linear(duration: Double(4 + i))
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.3),
                            value: floatHearts
                        )
                }
            }
        }
    }
}
