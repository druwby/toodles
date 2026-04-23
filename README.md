# Toodles — CPSC 491 Capstone

Video-dating iOS application built for CSUF CPSC 491, Spring 2026. Spontaneous 60-second WebRTC video chats with layered safety (trust score, report/block, university-email verification).

## Team

- **Danny Shtansky** 
- **Drew Butler** 
- **Vincent Polanco** 
- **Chaitanya Talluri**
- **Alan Tsan**

Faculty advisor: Dr. Kyoung Shin

## Architecture

Three-layer system per the capstone report:

- **Client Layer** — SwiftUI + Combine + MVVM, iOS 16+
- **Data Layer** — Firebase Authentication, Cloud Firestore, Firebase Storage (Spark free plan)
- **Video Layer** — Daily.co WebRTC SDK integration (`Toodles/Views/Video/Daily*.swift`, preserved behind `#if !DEMO_MODE`); `AVFoundation`-based demo mock in `MockVideoCallView.swift` used for the Spring 2026 demo submission

A reference implementation of the Firebase Cloud Functions backend (matchmaking, trust score, video session tokens) lives in the `TDV-28` feature branch under `backend-functions/` but is not deployed for the demo due to the Spark-plan / Blaze-plan billing boundary. The same logic is inlined client-side with Firestore security rules providing access control.

## Build

This project uses **XcodeGen** to generate the Xcode project from `project.yml`. The real `.xcodeproj` directory is gitignored and regenerated on every build.

### On macOS with local Xcode

```bash
brew install xcodegen
xcodegen generate
open Toodles.xcodeproj
```

Then `Cmd+R` in Xcode to build and run in the iOS Simulator.

### On Windows / Linux (via GitHub Actions)

GitHub Actions builds on `macos-14` runners on every push to `integration`, `main`, or `develop`. Download the `Toodles-simulator-app` artifact from the workflow run at <https://github.com/druwby/toodles/actions> and upload the resulting `.app` to [Appetize.io](https://appetize.io) for browser-based simulator testing.

This is the workflow used for the Spring 2026 capstone demo — no local Mac required on the developer's machine.

## Firebase setup

`GoogleService-Info.plist` is **not tracked in git** (it contains API keys). A template lives at `Toodles/Resources/GoogleService-Info.plist.example` — copy it to `GoogleService-Info.plist` in the same directory and fill in your Firebase project's values. If the plist is missing, the app still launches but all Firebase features (auth, Firestore, Storage) become no-ops — useful for previewing the UI without credentials.

### First-time setup

1. Go to <https://console.firebase.google.com>
2. Create a new project (name: `toodles-capstone` or similar)
3. Add an iOS app with bundle ID `edu.csuf.toodles`
4. Download `GoogleService-Info.plist` and save it to `Toodles/Resources/` (alongside the `.example` template).
5. In the Firebase Console, enable:
   - **Authentication** → Email/Password sign-in method
   - **Cloud Firestore** in production mode
   - **Storage** bucket (default region)
6. Firestore → Rules → paste contents of `firebase/firestore.rules`.

### GitHub Actions builds

The macOS runner needs the real plist at build time. Don't commit it — instead, store the file contents as a base64-encoded repository secret named `GOOGLE_SERVICE_INFO_PLIST_B64` and decode it in the workflow before `xcodegen generate`:

```yaml
- name: Write GoogleService-Info.plist from secret
  run: |
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST_B64 }}" | base64 -d \
      > Toodles/Resources/GoogleService-Info.plist
```

### Security note — key rotation

The previous `GoogleService-Info.plist` was tracked in git through **2026-04-23**. Any API key from that file must be assumed compromised. **Rotate it in the Firebase Console before shipping v1.1** (Project Settings → General → Web API Key → Regenerate, then re-download the plist for each app). The app-side Firebase security rules limit blast radius, but rotation is still required.

## Demo

The Spring 2026 capstone demo runs via Appetize.io and is screen-shared over Zoom. Expected flow:

1. Sign up with a `` / `@edu` email
2. Create profile (display name, bio, interests, photo)
3. Tap **Start Chatting** on Home → trust score check → matchmaking spinner → mock video call
4. 60-second countdown → Like / Pass / Report feedback
5. View match in Matches tab → chat with mutual likes in Chats tab
6. Submit a support ticket in the Support tab

See `docs/superpowers/specs/2026-04-08-toodles-capstone-rescue-design.md` for the full design spec and `docs/superpowers/plans/2026-04-08-toodles-capstone-rescue.md` for the implementation plan.
