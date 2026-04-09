import SwiftUI
import FirebaseCore

@main
struct ToodlesApp: App {
    init() {
        // Graceful Firebase init. If GoogleService-Info.plist is missing from
        // the bundle (e.g. before Danny has created the Firebase project),
        // skip configuration so the app can still launch as a "demo shell"
        // and faculty can preview the UI without Firebase setup.
        //
        // Note: We use the Firebase Auth REST API (in AuthManager) instead of
        // the iOS Auth SDK because Appetize.io's free-tier simulator blocks
        // Keychain access. FirebaseApp.configure() is still needed for
        // Firestore + Storage SDKs.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist not found — Firebase features disabled.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
