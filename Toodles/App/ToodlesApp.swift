import SwiftUI
import FirebaseCore

@main
struct ToodlesApp: App {
    init() {
        // Graceful Firebase init. If GoogleService-Info.plist is missing from
        // the bundle (e.g. before Danny has created the Firebase project),
        // skip configuration so the app can still launch as a "demo shell"
        // and faculty can preview the UI without Firebase setup.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
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
