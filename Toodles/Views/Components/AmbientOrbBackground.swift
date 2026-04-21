import SwiftUI

/// Shared modern background used across Onboarding, Home, StartChatting,
/// Signup, Login, and ProfileSetup. Deep-navy base gradient with three slowly
/// drifting blurred colour orbs. Mimics an iOS 18 `MeshGradient` without
/// actually requiring iOS 18.
struct AmbientOrbBackground: View {
    /// When true, the final darkening overlay is heavier — use this on screens
    /// that sit behind white input cards so the cards pop off the background.
    var intensity: Intensity = .standard

    enum Intensity { case soft, standard, heavy }

    @State private var orb1Offset: CGSize = CGSize(width: -80, height: -120)
    @State private var orb2Offset: CGSize = CGSize(width: 100,  height: 220)
    @State private var orb3Offset: CGSize = CGSize(width: -140, height: 240)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.16),
                    Color(red: 0.09, green: 0.09, blue: 0.28),
                    Color(red: 0.13, green: 0.10, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.42, green: 0.62, blue: 1.0).opacity(0.55))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(orb1Offset)

            Circle()
                .fill(Color(red: 0.98, green: 0.42, blue: 0.58).opacity(0.38))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(orb2Offset)

            Circle()
                .fill(Color(red: 0.98, green: 0.58, blue: 0.12).opacity(0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(orb3Offset)

            LinearGradient(
                colors: [
                    Color.black.opacity(darkeningTop),
                    Color.black.opacity(darkeningBottom)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                orb1Offset = CGSize(width: 100, height: -60)
            }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                orb2Offset = CGSize(width: -100, height: 40)
            }
            withAnimation(.easeInOut(duration: 13).repeatForever(autoreverses: true)) {
                orb3Offset = CGSize(width: 160, height: 220)
            }
        }
    }

    private var darkeningTop: Double {
        switch intensity {
        case .soft:     return 0.05
        case .standard: return 0.10
        case .heavy:    return 0.20
        }
    }

    private var darkeningBottom: Double {
        switch intensity {
        case .soft:     return 0.20
        case .standard: return 0.35
        case .heavy:    return 0.50
        }
    }
}
