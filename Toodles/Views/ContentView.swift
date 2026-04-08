import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()

    var body: some View {
        Group {
            if userViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(userViewModel)
            } else {
                OnboardingView(userViewModel: userViewModel)
            }
        }
    }
}
