import SwiftUI

/// Shown to unauthenticated users.
/// TODO (TDV-29): Replace mock login with real Firebase Auth.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("👋")
                .font(.system(size: 72))

            VStack(spacing: 8) {
                Text("Welcome to Toodles")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Real connections, one minute at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    // TODO (TDV-29): Hook up real Firebase Auth sign-in
                    appState.isLoggedIn = true
                } label: {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button("Sign In") {
                    // TODO (TDV-29): Hook up real Firebase Auth sign-in
                    appState.isLoggedIn = true
                }
                .foregroundStyle(.pink)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
