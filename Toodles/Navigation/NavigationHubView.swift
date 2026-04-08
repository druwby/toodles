// NavigationHubView.swift
// Toodles
// TDV-32: Navigation Hub & Social Continuity

import SwiftUI

enum NavigationTab: Int, CaseIterable {
    case discover
    case matches
    case reconnect
    case profile

    var title: String {
        switch self {
        case .discover: return "Discover"
        case .matches: return "Matches"
        case .reconnect: return "Reconnect"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .discover: return "video.fill"
        case .matches: return "heart.fill"
        case .reconnect: return "arrow.clockwise.circle.fill"
        case .profile: return "person.fill"
        }
    }
}

struct NavigationHubView: View {
    @State private var selectedTab: NavigationTab = .discover
    @StateObject private var socialContinuityManager = SocialContinuityManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverTabView()
                .tabItem {
                    Label(NavigationTab.discover.title, systemImage: NavigationTab.discover.icon)
                }
                .tag(NavigationTab.discover)

            MatchesListView()
                .tabItem {
                    Label(NavigationTab.matches.title, systemImage: NavigationTab.matches.icon)
                }
                .tag(NavigationTab.matches)

            ReconnectTabView()
                .tabItem {
                    Label(NavigationTab.reconnect.title, systemImage: NavigationTab.reconnect.icon)
                }
                .tag(NavigationTab.reconnect)

            ProfileTabView()
                .tabItem {
                    Label(NavigationTab.profile.title, systemImage: NavigationTab.profile.icon)
                }
                .tag(NavigationTab.profile)
        }
        .accentColor(.purple)
        .environmentObject(socialContinuityManager)
        .onAppear {
            Task { await socialContinuityManager.restoreSession() }
        }
    }
}

// Placeholder views for each tab
struct DiscoverTabView: View {
    var body: some View {
        NavigationView {
            Text("Discover")
                .navigationTitle("Discover")
        }
    }
}

struct ProfileTabView: View {
    var body: some View {
        NavigationView {
            Text("Profile")
                .navigationTitle("Profile")
        }
    }
}

struct NavigationHubView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationHubView()
    }
}
