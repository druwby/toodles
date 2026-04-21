import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingMatchmaking = false
    @State private var pulse1: CGFloat = 1.0
    @State private var pulse2: CGFloat = 1.0

    var body: some View {
        ZStack {
            AmbientOrbBackground(intensity: .standard)

            VStack(spacing: 0) {
                // Translucent top bar — replaces the solid ToodlesHeader so the ambient
                // background shows through. Keeps the same "Toodles" wordmark on the left.
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.caption.bold())
                        Text("Toodles")
                            .font(.body.bold())
                    }
                    .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)

                Spacer()

                // Hero cluster — matches landing page visual language
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulse1)

                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulse2)

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
                        .frame(width: 104, height: 104)
                        .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.40).opacity(0.55), radius: 24, y: 10)

                    Image(systemName: "video.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 24)

                Text("Meet Someone New")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(-0.8)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                    .padding(.bottom, 8)

                Text("One tap. A verified CSU Fullerton student. Sixty seconds of real video conversation.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 28)

                // Gradient CTA — mirrors landing page style
                Button {
                    showingMatchmaking = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.fill")
                        Text("Start Chatting")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 17)
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
                    .shadow(color: Color(red: 0.98, green: 0.45, blue: 0.30).opacity(0.55), radius: 16, y: 8)
                }

                Spacer()

                // Stats card — glass morphism + soft border
                statsCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)

                Text("By using this service, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 18)
            }
        }
        .fullScreenCover(isPresented: $showingMatchmaking) {
            StartChattingView(isPresented: $showingMatchmaking)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse1 = 1.12
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.4)) {
                pulse2 = 1.1
            }
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statPillar(icon: "checkmark.seal.fill", tint: Color(red: 0.42, green: 0.72, blue: 1.0), label: "Verified")
            Divider().frame(height: 40).background(Color.white.opacity(0.15))
            statPillar(icon: "timer", tint: Color(red: 0.98, green: 0.58, blue: 0.12), label: "60-sec")
            Divider().frame(height: 40).background(Color.white.opacity(0.15))
            statPillar(icon: "shield.lefthalf.filled", tint: Color(red: 0.98, green: 0.42, blue: 0.58), label: "Trust Score")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func statPillar(icon: String, tint: Color, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body.bold())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity)
    }
}
