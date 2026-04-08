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
        .tint(.orange)
    }
}
