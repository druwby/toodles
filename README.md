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

`GoogleService-Info.plist` lives at `Toodles/Resources/GoogleService-Info.plist` and is tracked in git for this capstone. The app bundle ID is locked to `edu.csuf.toodles` and Firebase's server-side security rules provide access control. If you need your own backend, replace the plist with one generated for your own Firebase project (bundle ID must match).

### Setting up a fresh Firebase project

1. Go to <https://console.firebase.google.com>
2. Create a new project
3. Add an iOS app with bundle ID `edu.csuf.toodles`
4. Download `GoogleService-Info.plist` and replace the one at `Toodles/Resources/`
5. In the Firebase Console, enable:
   - **Authentication** → Email/Password sign-in method
   - **Cloud Firestore** in production mode
   - **Storage** bucket (default region)
6. Firestore → Rules → paste contents of `firebase/firestore.rules`.

A template with placeholder values lives at `Toodles/Resources/GoogleService-Info.plist.example` for reference.

## Demo

The Spring 2026 capstone demo runs via Appetize.io and is screen-shared over Zoom. Expected flow:

1. Sign up with a `` / `@edu` email
2. Create profile (display name, bio, interests, photo)
3. Tap **Start Chatting** on Home → trust score check → matchmaking spinner → mock video call
4. 60-second countdown → Like / Pass / Report feedback
5. View match in Matches tab → chat with mutual likes in Chats tab
6. Submit a support ticket in the Support tab

See `docs/superpowers/specs/2026-04-08-toodles-capstone-rescue-design.md` for the full design spec and `docs/superpowers/plans/2026-04-08-toodles-capstone-rescue.md` for the implementation plan.
