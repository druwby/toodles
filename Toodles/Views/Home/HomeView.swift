import SwiftUI

struct HomeView: View {
    @State private var showingMatchmaking = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Talk to Strangers!")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Connect with random people around the world instantly")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Button {
                        showingMatchmaking = true
                    } label: {
                        Text("Start Chatting")
                            .font(.title3.bold())
                    }
                    .buttonStyle(ToodlesPrimaryButtonStyle())
                    .frame(width: 220)

                    Spacer()
                    Text("By using this service, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }
            }
            .fullScreenCover(isPresented: $showingMatchmaking) {
                StartChattingView(isPresented: $showingMatchmaking)
            }
            .navigationBarHidden(true)
        }
    }
}
