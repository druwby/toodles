import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    /// Force the tab bar to render as an opaque dark surface with our accent
    /// colour for the selected tab. SwiftUI's `.toolbarBackground(_:for:)`
    /// doesn't always stick — `.scrollEdgeAppearance` in particular falls back
    /// to a translucent material that makes inactive icons nearly invisible
    /// against the AmbientOrbBackground. Setting UITabBarAppearance via the
    /// appearance proxy is the reliable path.
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.16, alpha: 1.0)

        let inactive = UIColor.white.withAlphaComponent(0.55)
        appearance.stackedLayoutAppearance.normal.iconColor = inactive
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: inactive
        ]

        let active = UIColor(red: 0.98, green: 0.58, blue: 0.12, alpha: 1.0) // ToodlesTheme.accent
        appearance.stackedLayoutAppearance.selected.iconColor = active
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: active
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        // Chats tab removed — it duplicated Matches now that we hide
        // rejected/reported rows. Matches is the unified connections tab
        // that shows message previews and opens the chat on tap.
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            MatchesListView()
                .tabItem { Label("Matches", systemImage: "heart.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }

            SupportView()
                .tabItem { Label("Support", systemImage: "questionmark.circle.fill") }
        }
        .tint(ToodlesTheme.accent)
    }
}
