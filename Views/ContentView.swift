import SwiftUI

/// Root view — shows either the onboarding flow or the main tab bar
/// depending on authentication state held in AppState.
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isLoggedIn {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
