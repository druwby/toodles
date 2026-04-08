import SwiftUI

struct OnboardingView: View {
    @ObservedObject var userViewModel: UserViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.blue, .cyan.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "video.circle.fill")
                            .font(.system(size: 96))
                            .foregroundStyle(.white)
                        Text("Toodles")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Meet strangers in 60 seconds")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        NavigationLink("Sign Up", destination: SignupView(viewModel: userViewModel))
                            .buttonStyle(ToodlesPrimaryButtonStyle())

                        NavigationLink("I already have an account", destination: LoginView(viewModel: userViewModel))
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

struct ToodlesPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(configuration.isPressed ? Color.orange.opacity(0.7) : Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
