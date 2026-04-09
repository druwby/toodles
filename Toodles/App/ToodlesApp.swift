import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct ToodlesApp: App {
    init() {
        // Graceful Firebase init. If GoogleService-Info.plist is missing from
        // the bundle (e.g. before Danny has created the Firebase project),
        // skip configuration so the app can still launch as a "demo shell"
        // and faculty can preview the UI without Firebase setup.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            // Fix Keychain access on Appetize.io and other cloud-hosted iOS
            // Simulators: use the default (non-shared) access group so
            // Firebase Auth doesn't try to access a shared Keychain that
            // the sandboxed simulator doesn't have entitlements for.
            try? Auth.auth().useUserAccessGroup(nil)
        } else {
            print("⚠️ GoogleService-Info.plist not found — Firebase features disabled. Add the plist to Toodles/Resources/ to enable.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
