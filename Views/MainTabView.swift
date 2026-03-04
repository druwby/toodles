import SwiftUI

/// Primary navigation shell with three tabs: Connect, Matches, Profile.
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {

            ConnectView()
                .tabItem {
                    Label("Connect", systemImage: "video.fill")
                }
                .tag(AppState.Tab.connect)

            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
                .tag(AppState.Tab.matches)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppState.Tab.profile)
        }
        .accentColor(.pink)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
