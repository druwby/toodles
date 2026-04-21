import SwiftUI

struct OnboardingView: View {
    @ObservedObject var userViewModel: UserViewModel

    // Hero ring pulses
    @State private var pulse1: CGFloat = 1.0
    @State private var pulse2: CGFloat = 1.0

    // Staggered reveal
    @State private var heroVisible = false
    @State private var featuresVisible = false
    @State private var ctaVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientOrbBackground(intensity: .standard)

                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    heroSection
                        .opacity(heroVisible ? 1 : 0)
                        .offset(y: heroVisible ? 0 : 12)
                        .padding(.bottom, 32)

                    featuresCard
                        .padding(.horizontal, 22)
                        .opacity(featuresVisible ? 1 : 0)
                        .offset(y: featuresVisible ? 0 : 18)

                    Spacer(minLength: 36)

                    buttonsSection
                        .padding(.horizontal, 28)
                        .padding(.bottom, 44)
                        .opacity(ctaVisible ? 1 : 0)
                        .offset(y: ctaVisible ? 0 : 24)
                }
            }
            .onAppear { startAnimations() }
        }
        .tint(.white)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 2)
                    .frame(width: 210, height: 210)
                    .scaleEffect(pulse1)

                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
                    .frame(width: 160, height: 160)
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
                    .frame(width: 116, height: 116)
                    .shadow(color: Color(red: 0.98, green: 0.42, blue: 0.58).opacity(0.6), radius: 28, y: 10)

                Image(systemName: "video.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Toodles")
                .font(.system(size: 60, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
                .tracking(-1.5)

            Text("Video dating, reinvented.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.88))
        }
    }

    // MARK: - Feature card (glass-morphism)

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(
                icon: "bolt.fill",
                tint: Color(red: 0.98, green: 0.58, blue: 0.12),
                title: "60-second video chats",
                subtitle: "Real conversation. No endless swiping."
            )
            featureRow(
                icon: "checkmark.seal.fill",
                tint: Color(red: 0.42, green: 0.72, blue: 1.0),
                title: "CSUF-verified students only",
                subtitle: "Every match confirmed by university email."
            )
            featureRow(
                icon: "shield.lefthalf.filled",
                tint: Color(red: 0.98, green: 0.42, blue: 0.58),
                title: "Safety is the default",
                subtitle: "Trust Score plus one-tap moderation."
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 18, y: 8)
    }

    private func featureRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.22))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
    }

    // MARK: - CTA

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            NavigationLink {
                SignupView(viewModel: userViewModel)
            } label: {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.title3.bold())
                    Image(systemName: "arrow.right")
                        .font(.body.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
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

            NavigationLink {
                LoginView(viewModel: userViewModel)
            } label: {
                HStack(spacing: 6) {
                    Text("I already have an account")
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                }
                .font(.callout.bold())
                .foregroundStyle(.white.opacity(0.95))
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Staggered in-reveal
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            heroVisible = true
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.25)) {
            featuresVisible = true
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.45)) {
            ctaVisible = true
        }

        // Pulsing rings around the hero
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            pulse1 = 1.15
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.4)) {
            pulse2 = 1.12
        }
    }
}

// NOTE: ToodlesPrimaryButtonStyle is defined in Toodles/Views/Components/ToodlesTheme.swift
