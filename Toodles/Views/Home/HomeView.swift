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

                    Text("Talk to Strangers!")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 12)

                    Text("Connect with random people around the world instantly")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)

                    Button {
                        showingMatchmaking = true
                    } label: {
                        Text("Start Chatting")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 18)
                            .background(ToodlesTheme.accent)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text("By using this service, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
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
}
