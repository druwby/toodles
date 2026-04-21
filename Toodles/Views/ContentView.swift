import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()

    var body: some View {
        Group {
            if !userViewModel.isAuthenticated {
                OnboardingView(userViewModel: userViewModel)
            } else if userViewModel.currentUser == nil {
                // Signed in, but the Firestore profile hasn't loaded back yet.
                // Show a loading splash so we don't flash MainTabView and then
                // immediately swap to the setup gate (or vice versa).
                loadingSplash
            } else if needsProfileSetup {
                // Profile-completeness gate (Hinge/Tinder-style). User must have
                // uploaded a profile photo before they can access the main tabs.
                ProfileSetupView()
                    .environmentObject(userViewModel)
            } else {
                MainTabView()
                    .environmentObject(userViewModel)
            }
        }
    }

    /// True when the signed-in user hasn't uploaded a profile photo yet.
    private var needsProfileSetup: Bool {
        guard let user = userViewModel.currentUser else { return false }
        let photo = user.profilePhotoUrl ?? ""
        return photo.isEmpty
    }

    private var loadingSplash: some View {
        ZStack {
            ToodlesTheme.bodyGradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "video.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                Text("Toodles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
        }
    }
}
