# Toodles Capstone Rescue — Design

- **Date:** 2026-04-08
- **Author:** Danny Shtansky (with Claude as pair)
- **Status:** Approved by Danny in principle; self-reviewed; pending final written-spec user review before transitioning to implementation plan
- **Target submission:** CPSC 491 Capstone demo, ~2026-04-11/12 (Sat/Sun), via Zoom
- **Approach:** A — Hybrid (harvest existing team work + new integration scaffolding)
- **Related docs:** `TD-Toodles ProjectPreview.pdf` (CPSC 491 capstone report draft), Jira epic TDV-20, Confluence "Toodles - Project Report" page

## 1. Executive Summary

Toodles is a CSUF CPSC 491 capstone project: a native iOS video-dating application built with SwiftUI, Firebase, and Daily.co, offering spontaneous 60-second WebRTC video chats layered with safety features (trust score, liveness detection, in-session reporting).

The **capstone report PDF is written in past tense claiming the prototype is delivered**, but the actual repository state (`github.com/druwby/toodles`) tells a different story:

- 46 branches, only **1 PR ever merged to `main`**
- `main` has 13 Swift files, no Xcode project, no app entry point, no buildable target
- `develop` has only `.gitignore`
- **No Xcode project file (`.xcodeproj`) exists on any branch** — nothing has ever been compiled
- No Firebase project exists in the cloud (the "Firebase backend" from the PDF is vaporware)
- Danny (the only active contributor) has authored **18 of 19 PRs**, all unmerged
- Danny works on Windows 10, cannot build SwiftUI locally

This spec documents the 3-day rescue plan to deliver a Zoom-demonstrable iOS build matching the PDF's promises, without local Mac access, without a real Daily.co API key, and without additional team help.

## 2. Context and Constraints

### 2.1 The team

Per Confluence member contributions:

| Member | Listed role | Actual output |
|---|---|---|
| Danny Shtansky (this user) | PM, Lead iOS Dev, Jira, Confluence | 18 unmerged PRs, all Swift code |
| Drew Butler | iOS Dev, Backend Integration | Repo owner; no PRs authored; pushed to repo today (2026-04-08) |
| Vincent Polanco | iOS Dev, UI/UX | No PRs authored |
| Chaitanya Talluri | — | 1 PR authored and merged (TDV-40) |
| Alan Tsan | — | No PRs authored |

**Operational assumption:** Danny executes this plan solo. Teammates are not blockers and will not be asked to contribute to the rescue.

### 2.2 Hard constraints

1. **No local Mac:** Danny's workstation is Windows 10. Xcode cannot run natively on Windows. No VM workarounds (Apple EULA prohibits). No Hackintosh.
2. **No Apple Developer account:** $99/year fee is out of scope; demo must run on iOS Simulator, not a real device.
3. **Tight deadline:** 3 working days until Zoom demo.
4. **No Daily.co API access:** Real WebRTC video is out of scope for the demo.
5. **No Firebase Cloud Functions budget:** The PDF-described Cloud Functions backend requires the Firebase Blaze plan (billing account). Plan uses Spark (free) tier only.

### 2.3 Soft constraints

1. The PDF commits to specific architecture (SwiftUI + Combine + MVVM + Firebase + Daily.co). Final code must visibly match this stack, even where functionality is simplified.
2. Jira history and the 18 unmerged PRs should be respected — the rescue reuses the team's existing Swift code wherever possible rather than discarding it.
3. The rescue should produce code Danny can honestly claim as his own during the oral demo (he wrote most of it originally; Claude helps with integration, missing pieces, and fixes).

## 3. Goals

1. **A compilable Xcode project** on an `integration` branch of `druwby/toodles`, built via GitHub Actions on a cloud macOS runner.
2. **A Firebase project** (created fresh under Danny's Google account) with Auth, Firestore, and Storage configured.
3. **An end-to-end demo flow** covering: signup → profile → Start Chatting → 60-sec video → post-session feedback → matches → 1:1 chat → support ticket.
4. **A public Appetize.io URL** that plays the latest simulator build in any browser.
5. **A Zoom-shareable presentation** with a recorded backup video in case the live demo fails.
6. **Honest Jira and Confluence state** that reflects what was actually built.

## 4. Non-Goals (Scope Boundaries)

The following are **explicitly not in scope** and will be documented as "future work" in the updated report or silently scoped down:

- Real Daily.co WebRTC video integration (code preserved in repo behind `DEMO_MODE` compilation flag)
- Firebase Cloud Functions backend deployment (Trust Gate + matchmaking inlined client-side)
- Face Liveness Detection via AWS Rekognition (stubbed as a "Verified" checkmark in the profile editor)
- AI-assisted text/speech/audio moderation (already "future work" per PDF Section 3.1)
- Advanced Trust Score decay/reward model (score stays at default 100 for demo users)
- Text-based language filtering (TDV-49)
- Push notifications
- Real-device deployment or App Store distribution
- Unit tests and integration tests
- Accessibility audit, dark mode, localization

**Rule:** If faculty asks about any non-goal during the demo, the honest answer is "that's documented as future work in our report — we prioritized the core flow for the demo."

## 5. Architecture

### 5.1 Layered view (matches PDF Figure 1)

```
┌───────────────────────────────────────────────────────────┐
│                  Client Layer (iOS)                       │
│   SwiftUI + Combine, MVVM pattern                         │
│   Views ── ViewModels ── Services ── Firebase SDKs        │
└───────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴──────────────┐
                ▼                            ▼
┌──────────────────────────────┐   ┌────────────────────────┐
│    Firebase Backend          │   │   Video (MOCKED)       │
│  Auth, Firestore, Storage    │   │   AVFoundation camera  │
│  (Spark plan, no Functions)  │   │   + 60-sec timer view  │
│                              │   │   Daily.co code present│
│  Trust Gate = Firestore rule │   │   behind DEMO_MODE flag│
│  Matchmaking = client pool   │   │                        │
└──────────────────────────────┘   └────────────────────────┘
```

### 5.2 Tech stack (final)

| Layer | Technology | Source |
|---|---|---|
| UI | SwiftUI | Harvested from TDV-33, TDV-50; new views where missing |
| State | Combine (`@Published` on ObservableObject ViewModels) | Pattern from harvested code |
| Auth | Firebase Auth (Email/Password + client-side domain regex) | New `AuthManager.swift` |
| Data | Cloud Firestore (5 collections per ERD) | Harvested `FirestoreService.swift`, extended |
| Storage | Firebase Storage (profile photos) | New `StorageService.swift` |
| Video | `AVFoundation` mock (primary) + Daily.co code behind `#if DEMO_MODE` else branch (inactive) | Mock is new; Daily code harvested from TDV-41 |
| Build tool | **XcodeGen** (YAML → `.xcodeproj`) | New `project.yml` |
| CI | GitHub Actions `macos-14` runner | New `.github/workflows/ios-build.yml` |
| Demo host | Appetize.io (free simulator hosting) | External |

### 5.3 Deviation from PDF architecture

The PDF describes Firebase Cloud Functions as the "Serverless Logic Layer" executing Trust Score calculation and matchmaking. **This rescue inlines that logic client-side** to avoid the Blaze (paid) plan requirement. Concretely, the "Trust Gate" becomes a client-side check of `currentUser.trust_score >= 50` executed by `StartChattingViewModel` immediately before matchmaking, backed by a Firestore security rule that prevents users from writing to their own `trust_score` field. "Matchmaking" becomes a Firestore-based waiting pool: `MatchmakingService` writes the current user to `/waitingPool/{uid}` with a server timestamp, listens for a partner, and returns a match when one arrives (or a simulated fake match for the demo after ~2-3 seconds).

Faculty impact:

- **Visually**: identical — the demo shows "Checking trust score…" spinner and "Looking for a match…" spinner, same as with real Cloud Functions.
- **Code inspection**: the `TDV-28` branch's TypeScript Cloud Functions (`matchmaking.ts`, `trustScore.ts`, `videoSessions.ts`, `userManagement.ts`) are **preserved in the `firebase/functions/` directory** of the integration branch as reference code, marked in the README as "reference implementation, not deployed for the demo due to Blaze plan requirement." This matches what the PDF describes without requiring deployment.
- **Oral defense**: honest answer — "we wrote the Cloud Functions but didn't deploy them because of billing constraints on the Spark free tier; the same logic runs client-side with Firestore security rules enforcing access control."

## 6. Component Design (File Layout)

```
toodles/
├── project.yml                           ← NEW (XcodeGen spec)
├── .github/workflows/ios-build.yml       ← NEW (CI build on macos-14)
├── .gitignore                            ← existing, extend with GoogleService-Info.plist
├── README.md                             ← NEW (short, for faculty)
├── Toodles/                              ← Xcode target root
│   ├── App/
│   │   ├── ToodlesApp.swift              ← HARVEST (TDV-33) + extend
│   │   ├── AppState.swift                ← HARVEST (TDV-33)
│   │   └── AuthManager.swift             ← NEW (referenced by UserViewModel, missing)
│   ├── Resources/
│   │   ├── Info.plist                    ← NEW (camera/mic/photo permission strings)
│   │   └── GoogleService-Info.plist      ← DANNY downloads from Firebase Console (gitignored)
│   ├── Models/
│   │   └── Models.swift                  ← HARVEST + extend (User, Match, Chat, Message, SupportTicket)
│   ├── Services/
│   │   ├── FirestoreService.swift        ← HARVEST + fix deprecated FirebaseFirestoreSwift import
│   │   ├── StorageService.swift          ← NEW
│   │   └── MatchmakingService.swift      ← HARVEST (TDV-42) + simplify (no Cloud Functions)
│   ├── ViewModels/
│   │   ├── UserViewModel.swift           ← HARVEST (rename .Swift → .swift for case safety)
│   │   ├── HomeViewModel.swift           ← HARVEST (TDV-50)
│   │   ├── ProfileViewModel.swift        ← HARVEST (TDV-33) + extend
│   │   ├── MatchesViewModel.swift        ← NEW
│   │   └── ChatViewModel.swift           ← NEW
│   ├── Views/
│   │   ├── ContentView.swift             ← HARVEST (TDV-33) — routes auth state
│   │   ├── MainTabView.swift             ← HARVEST (TDV-33) — 5 tabs
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift      ← HARVEST (TDV-33)
│   │   │   ├── LoginView.swift           ← NEW
│   │   │   └── SignupView.swift          ← NEW (Fullerton email validation)
│   │   ├── Home/
│   │   │   └── HomeView.swift            ← HARVEST (TDV-50) — Start Chatting button
│   │   ├── Chat/
│   │   │   ├── StartChattingView.swift   ← HARVEST (TDV-42)
│   │   │   ├── StartChattingViewModel.swift ← HARVEST (TDV-42)
│   │   │   ├── PostSessionFeedbackView.swift ← NEW (Like/Dislike/Report)
│   │   │   ├── ChatListView.swift        ← NEW
│   │   │   └── ChatDetailView.swift      ← NEW (1:1 Firestore listener)
│   │   ├── Matches/
│   │   │   └── MatchesListView.swift     ← NEW
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift         ← HARVEST (TDV-33)
│   │   │   └── EditProfileView.swift     ← NEW (photo upload + bio + interests)
│   │   ├── Video/
│   │   │   ├── MockVideoCallView.swift   ← NEW (AVFoundation primary path)
│   │   │   ├── DailyVideoCallView.swift  ← HARVEST (TDV-41) — behind DEMO_MODE flag
│   │   │   ├── DailyVideoCallViewModel.swift ← HARVEST (TDV-41)
│   │   │   ├── DailyRoomManager.swift    ← HARVEST (TDV-41)
│   │   │   └── DailyVideoService.swift   ← HARVEST (TDV-41)
│   │   ├── Safety/
│   │   │   ├── ModerationView.swift      ← HARVEST (main)
│   │   │   ├── ReportingService.swift    ← HARVEST (main)
│   │   │   └── TrustScoreManager.swift   ← HARVEST (main) — client-side only
│   │   └── Support/
│   │       └── SupportView.swift         ← NEW (Customer Support tab)
├── firebase/                             ← HARVEST (TDV-28) — reference only, not deployed
│   ├── firestore.rules                   ← HARVEST + simplify for rescue
│   ├── firestore.indexes.json            ← HARVEST
│   ├── firebase.json                     ← HARVEST
│   └── functions/                        ← HARVEST (TDV-28) — reference, not deployed
└── docs/superpowers/specs/
    └── 2026-04-08-toodles-capstone-rescue-design.md  ← THIS FILE
```

**Totals:** ~30 Swift files in target, ~17 harvested from existing branches, ~13 new.

## 7. Demo User Flow

The exact sequence Danny will screen-share over Zoom. Every step must work end-to-end. Nothing outside this list is in scope.

1. **App launches** → `ContentView` checks auth state
   - Logged out → `OnboardingView` → Signup or Login
   - Logged in → `MainTabView` (Home / Matches / Chats / Profile / Support)
2. **SignupView**: email (`@csu.fullerton.edu` / `@fullerton.edu` regex), password, display name → `AuthManager.signup()` → creates Firebase user → `FirestoreService.createUser()` → writes `/users/{uid}` → routes to `EditProfileView` for first-time setup
3. **EditProfileView**: display name, bio (150 char limit), interests tags, photo upload (PHPicker → Firebase Storage) → updates `/users/{uid}.profilePhotoUrl` → returns to `HomeView`
4. **HomeView**: "Talk to Strangers!" title, subtitle, **[Start Chatting]** orange button → `StartChattingView`
5. **StartChattingView**: "Checking trust score…" (client-side: `trust_score >= 50`) → "Looking for a match…" (~2-3 sec simulated) → navigates to `MockVideoCallView` with fake "Alex Johnson" match
6. **MockVideoCallView**: full-screen front camera feed (`AVCaptureVideoPreviewLayer`), "Alex Johnson" label, silhouette remote placeholder, 60-sec countdown timer, [Mute] [Flip Camera] [End Call] → at 0:00 or [End Call] → `PostSessionFeedbackView`
7. **PostSessionFeedbackView**: shows match profile, 3 buttons: 👍 Like / 👎 Dislike / 🚩 Report → writes `/matches/{matchId}` with status. Report also creates `/supportTickets/{ticketId}` with `category=report_user`. Returns to `HomeView`.
8. **MatchesListView** (tab): fetches `/matches/` where `user_a_id==uid` or `user_b_id==uid`, status in `[matched, added]`. Lists matches with timestamp and action icons. Tap → `ChatDetailView`
9. **ChatListView** (tab): lists chats where both users mutual-liked. Tap → `ChatDetailView`
10. **ChatDetailView**: real-time Firestore snapshot listener on `/chats/{chatId}/messages`. Message bubbles. Text input + Send button writes new doc.
11. **ProfileView** (tab): own photo, name, bio, interests, [Edit Profile] and [Sign Out] buttons
12. **SupportView** (tab): 3 category buttons (Report User / App Feedback / Technical Help), subject + description → `/supportTickets/{ticketId}` → confirmation

This covers PDF FRs 01-07 plus Support. FR-08 (Trust Score) is client-side only; FR-04 (Liveness) is stubbed.

## 8. Build Pipeline

### 8.1 XcodeGen (`project.yml`)

Defines the Xcode target, Swift packages (Firebase iOS SDK, optionally Daily.co), source paths, resources, and the `DEMO_MODE` compilation flag. Committed to git. Regenerated on every CI run.

### 8.2 GitHub Actions (`.github/workflows/ios-build.yml`)

Triggers on push to `integration`, `main`, `develop`, or manual dispatch. Runs on `macos-14`. Steps:

1. Checkout
2. `brew install xcodegen`
3. `xcodegen generate`
4. Select Xcode 15.4
5. `xcodebuild -resolvePackageDependencies`
6. `xcodebuild build` for iOS Simulator
7. Zip the resulting `.app` bundle
8. Upload as workflow artifact (retained 7 days)

**Cost:** $0 — public repo, unlimited macOS minutes per GitHub's open-source subsidy.

### 8.3 Appetize.io

After each successful CI build, Danny downloads the artifact, unzips, uploads `Toodles.app` to https://appetize.io/upload as a Simulator build, gets a public browser URL, and uses that URL for the Zoom demo. Free tier: 100 minutes/month, sufficient for rehearsal + live demo + backup recording.

### 8.4 Backup demo recording

During final rehearsal, Danny screen-records a successful end-to-end run via OBS Studio (free, Windows) and saves locally. If Appetize has issues during the live demo, Danny pivots to playing the recorded video.

## 9. Firebase Setup

**One-time, ~15 minutes, performed by Danny after Day 1 scaffold compiles:**

1. `console.firebase.google.com` → Add project → name: `toodles-capstone` → skip Analytics
2. Add iOS app → bundle ID `edu.csuf.toodles` (must match `project.yml`) → nickname "Toodles iOS"
3. **Download `GoogleService-Info.plist`** → paste into `Toodles/Resources/GoogleService-Info.plist` → **commit it to the repo**. Firebase iOS client plists are explicitly designed to be public (the `API_KEY` inside is a client API key with no privileged access; security is enforced by Firestore rules, not by hiding the file). Committing it lets GitHub Actions CI builds succeed without special handling.
4. Authentication → Sign-in method → Email/Password → Enable
5. Firestore Database → Create → production mode → default region
6. Storage → Create bucket → production mode → default region
7. (Optional) Firestore → Rules → paste contents of `firebase/firestore.rules` from the repo
8. (Optional) Firestore → Indexes → paste contents of `firebase/firestore.indexes.json`

**No Cloud Functions deployment.** The `firebase/functions/` directory exists as reference code only.

## 10. Execution Plan

### Day 1 — Wednesday 2026-04-08 (today)

**Goal:** scaffold compiles and launches a non-crashing app on Appetize; Firebase project exists.

| # | Task | Owner |
|---|---|---|
| 1.1 | Create local `integration` branch from `main` | Claude — local branch created, not yet pushed |
| 1.2 | Write `project.yml` | Claude |
| 1.3 | Write `.github/workflows/ios-build.yml` | Claude |
| 1.4 | Write minimal `ToodlesApp.swift`, `ContentView.swift`, `Info.plist` | Claude |
| 1.5 | Commit + push integration branch → trigger first CI build | Claude (asks Danny for push permission) |
| 1.6 | Iterate on CI errors until green | Claude + CI |
| 1.7 | Danny: create Firebase project, enable Auth + Firestore + Storage, download `GoogleService-Info.plist`, paste into repo, commit | Danny |
| 1.8 | Harvest existing team files into per-layout directories | Claude |
| 1.9 | Second CI build with harvested code → iterate on errors | Claude + CI |
| 1.10 | Download the built `Toodles.app` artifact, upload to Appetize.io, verify the app launches without crashing (OnboardingView visible) | Danny + Claude (guides) |

### Day 2 — Thursday 2026-04-09

**Goal:** full end-to-end demo flow runs on Appetize without crashes.

| # | Task | Owner |
|---|---|---|
| 2.1 | Wire Auth (AuthManager + LoginView + SignupView + email regex) | Claude |
| 2.2 | Wire Profile (EditProfileView + photo upload via StorageService) | Claude |
| 2.3 | Wire Home → Start Chatting → MockVideoCallView (AVFoundation + timer) | Claude |
| 2.4 | Wire PostSessionFeedbackView (writes to `/matches`) | Claude |
| 2.5 | Wire MatchesListView (Firestore query) | Claude |
| 2.6 | Wire ChatListView + ChatDetailView (snapshot listener) | Claude |
| 2.7 | Wire SupportView (writes to `/supportTickets`) | Claude |
| 2.8 | First full end-to-end demo run on Appetize; fix runtime bugs | Claude + Danny |

### Day 3 — Friday 2026-04-10

**Goal:** polished, rehearsed demo with backup video.

| # | Task | Owner |
|---|---|---|
| 3.1 | UI polish (Figma colors, fonts, spacing) | Claude |
| 3.2 | Copy/text pass | Claude |
| 3.3 | Rehearse demo flow 5 times on Appetize | Danny |
| 3.4 | Record backup demo via OBS Studio | Danny |
| 3.5 | Update Jira board to reflect reality | Danny |
| 3.6 | Update Confluence project report to reflect reality | Danny |
| 3.7 | Write short `README.md` for the repo | Claude |
| 3.8 | Final push → final CI build → final Appetize upload | Claude + Danny |

### Day 4 — Saturday/Sunday 2026-04-11/12 (buffer + demo day)

Reserved for (a) fixing anything that breaks in final rehearsal, (b) actually doing the Zoom demo.

## 11. Risk Register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | First CI build fails with Firebase SDK version errors | High | Medium | Budgeted 1-2 hours Day 1. If errors exceed 30, pin Firebase SDK to 10.x instead of 11.x |
| R2 | Harvested code has runtime bugs that only appear at launch | High | Medium | Day 2 is mostly "run on Appetize, watch crash, fix." Normal for a rescue |
| R3 | Appetize.io webcam passthrough doesn't work in Chrome | Medium | High | Test Day 1 with throwaway app. Fallback: static gradient for local video, keep mute/hangup controls |
| R4 | Firebase Auth email domain validation regex edge cases | Low | Low | Test with `@csu.fullerton.edu`, `@fullerton.edu`, bad `@gmail.com` |
| R5 | Firestore security rules reject legitimate demo reads | Medium | High | Test every rule in Firebase Rules Playground before demo |
| R6 | GitHub Actions macOS runner intermittent failures | Low | Medium | Re-run with one click, 10-min buffer |
| R7 | Danny loses a day to other obligations | Medium | High | Degrade to Approach C if Day 2 runs 12+ hours over |
| R8 | Daily.co harvested code refuses to compile even behind flag | Medium | Low | Remove Daily files from `project.yml` sources entirely if they can't compile |
| R9 | Faculty asks for live two-user video chat | Low | Medium | Honest answer: "single-user demo due to SDK + test device constraints; full Daily.co integration is in the codebase" |
| R10 | Appetize free tier (100 min/mo) exhausted mid-demo | Very low | High | Fall back to locally-recorded backup video |

## 12. Success Criteria

By the time Danny starts the Zoom demo, all of these are true:

1. ✅ Public Appetize.io URL plays the latest build
2. ✅ 12-step demo flow runs end-to-end without crash on that URL
3. ✅ Firebase project exists, Firestore writes visible in Console
4. ✅ `demo-backup.mp4` exists locally
5. ✅ `druwby/toodles` `integration` branch pushed, latest CI build green
6. ✅ Jira board reflects reality (no false "Done" items)
7. ✅ Danny has practiced the demo narration out loud at least twice

## 13. Open Questions

- **Does `druwby/toodles` become the canonical submission repo, or does Danny fork it to his own GitHub account to own the grade?** Defer decision until Day 3 polish step; if Drew is uncontactable, Danny may want to fork to own the submission independently.
- **Does the Confluence page update need to happen before or after the Jira board update?** Both are Day 3, order irrelevant.
- **Does Kyoung Shin want a separate written capstone report submission, or is the PDF already the final report?** Unknown. Danny to check Canvas.

## 14. References

- `C:\Users\riven\Downloads\TD-Toodles ProjectPreview.pdf` — CPSC 491 capstone report draft
- Jira epic: `https://cortado.atlassian.net/browse/TDV-20`
- Confluence project report: `https://cortado.atlassian.net/wiki/spaces/TD/pages/4096001`
- Repo: `https://github.com/druwby/toodles` (default branch `main`)
- XcodeGen: `https://github.com/yonaskolb/XcodeGen`
- Appetize.io: `https://appetize.io`
- GitHub Actions macOS runners: `https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners`
