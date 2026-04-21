import SwiftUI

struct HomeView: View {
    @State private var showingMatchmaking = false

    var body: some View {
        VStack(spacing: 0) {
            ToodlesHeader(title: "Toodles", showCameraIcon: true)

            ZStack {
                ToodlesTheme.bodyGradient.ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    Spacer()

                    // Pulsing ring / camera cluster — draws the eye to the CTA
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 170, height: 170)
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            .frame(width: 130, height: 130)
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 96, height: 96)
                        Image(systemName: "video.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 28)

                    Text("Meet Someone New")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 10)

                    Text("One tap. A verified CSU Fullerton student. Sixty seconds of real video conversation.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)

                    Button {
                        showingMatchmaking = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                            Text("Start Chatting")
                                .font(.title3.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 17)
                        .background(ToodlesTheme.accent)
                        .clipShape(Capsule())
                        .shadow(color: ToodlesTheme.accent.opacity(0.45), radius: 14, y: 6)
                    }

                    Spacer()

                    // Trust-story strip — three small pillars below the CTA. Gives the Home
                    // tab something to read without taking focus from the button.
                    HStack(spacing: 24) {
                        featurePill(icon: "checkmark.seal.fill", label: "Verified CSUF")
                        featurePill(icon: "timer", label: "60-sec")
                        featurePill(icon: "shield.lefthalf.filled", label: "Trust Score")
                    }
                    .padding(.bottom, 16)

                    Text("By using this service, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showingMatchmaking) {
            StartChattingView(isPresented: $showingMatchmaking)
        }
    }

    private func featurePill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(label)
                .font(.caption.bold())
        }
        .foregroundStyle(.white.opacity(0.95))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.15))
        .clipShape(Capsule())
    }
}
