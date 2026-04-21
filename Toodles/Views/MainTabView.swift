import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            MatchesListView()
                .tabItem { Label("Matches", systemImage: "heart.fill") }

            ChatListView()
                .tabItem { Label("Chats", systemImage: "message.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }

            SupportView()
                .tabItem { Label("Support", systemImage: "questionmark.circle.fill") }
        }
        .tint(ToodlesTheme.accent)
        // Force the tab bar to use the dark-ambient palette so inactive icons
        // are legible against the AmbientOrbBackground. Without this the tab
        // bar picks up the system background and the gray inactive icons
        // disappear on the dark gradient.
        .toolbarBackground(
            Color(red: 0.04, green: 0.05, blue: 0.16),
            for: .tabBar
        )
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
