import Foundation
import Combine

/// Global application state managed via Combine.
/// @Published properties cause SwiftUI views to reactively re-render on changes.
final class AppState: ObservableObject {

    // MARK: - Auth State
    @Published var isLoggedIn: Bool = false

    // MARK: - Navigation
    @Published var selectedTab: Tab = .connect

    enum Tab: Int {
        case connect, matches, profile
    }
}
