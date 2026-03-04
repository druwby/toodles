import Foundation
import Combine

/// ViewModel for ProfileView.
/// TODO (TDV-38): Wire save() to Firestore once backend is ready.
final class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var bio: String = ""

    func save() {
        // TODO (TDV-38): Persist changes to Firestore
        print("[ProfileViewModel] Save tapped — Firestore write goes here")
    }
}
