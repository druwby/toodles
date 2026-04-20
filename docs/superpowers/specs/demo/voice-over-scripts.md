# Voice-Over Scripts — Day 2, Audacity

Read each scene as a separate Audacity recording. One WAV per scene = cheap retakes.

## Audacity setup (do once at start of session)

1. Install Audacity (free, audacityteam.org)
2. Plug in headset mic OR use phone Voice Memos app in a quiet room
3. Audacity → Transport, set sample rate **44100 Hz**
4. Record **6 seconds of silence** (for noise-reduction profile)
5. Select the silence → **Effect → Noise Reduction → Get Noise Profile**
6. Now record each scene below

## After each recording

1. Select all (Ctrl+A)
2. **Effect → Noise Reduction → OK** (uses the profile from step 5)
3. **Effect → Compressor → OK** (defaults are fine)
4. **Effect → Normalize → target -1.0 dB → OK**
5. **File → Export → Export as WAV** → name `scene01.wav`, `scene02.wav`, etc.

---

## Scene 1 — Cold Open (target 20 sec, ~135 wpm)

> Dating apps train you to scroll, judge, and ghost. [PAUSE 0.5] Toodles does the opposite. One tap connects you with a verified CSU Fullerton student for a sixty-second video chat. [PAUSE 0.3] No profiles to polish. No messages to ignore. [PAUSE 0.3] Just real conversations, sixty seconds at a time.

**Delivery:** first sentence flat and weary — this is the indictment. Pause fully before "Toodles does the opposite" — let the contrast land. Accelerate through the middle. Final line slow — it's the tagline.

---

## Scene 2 — Tech Stack (target 15 sec)

> Toodles is built native for iOS using SwiftUI and Combine in the MVVM pattern. Authentication and data sync run on Firebase — restricted to verified university email domains. Video is peer-to-peer WebRTC through the Daily dot co SDK, and server logic runs on Firebase Cloud Functions.

**Delivery:** informative, not hyped. This is the credibility paragraph. Land "peer-to-peer WebRTC" with slight emphasis.

---

## Scene 3 — Auth (target 25 sec)

> A student signs up with their CSU Fullerton email. Firebase Auth verifies the domain — non-university addresses are rejected at the boundary.

**Delivery:** confident, matter-of-fact. 15 words over 25 sec of video = don't rush. Leave breathing room for the rejection → acceptance visual to play.

---

## Scene 4 — Profile (target 30 sec)

> After verification, users build a lightweight profile — name, year, one prompt, one photo. Profile photos upload to Firebase Storage. The goal is minimal friction: you're here to talk, not to curate.

---

## Scene 5 — Matching (target 40 sec)

> From the home screen, one tap on "Start Chatting" triggers the Trust Gate — a Cloud Function that verifies the user's standing and issues a Daily dot co room token. Two users are matched into the same ephemeral room.

**Delivery:** pace slower than Scene 2. The technical detail lands better when words breathe.

---

## Scene 6 — 60-Second Video Chat (target 60 sec) — **USE THIS ONE**

You built a `MockVideoCallView` with a Tinder-dark UI specifically for environments where camera passthrough isn't available. That's *your engineering work* — own it in the VO:

> Here's the core Toodles experience: one sixty-second video chat, peer-to-peer through Daily dot co. Because the Daily SDK needs real camera hardware, we built a mock video call view for test environments like browser-based simulators — what you're seeing now. In production on a physical iOS device, the two tiles stream the users' real cameras. Everything else in this flow is live — the Daily room, the server-enforced timer, the auto-close at zero, the transition to the feedback screen.

**Delivery:** slow, factual, proud. This is not an apology — it's describing a deliberate engineering choice. You architected a DEMO_MODE path specifically so the app would be demoable without real hardware. That's a point you *earn* grading credit for.

**Alternative (simpler, no mock-mode call-out):**

> Here's the core Toodles experience: one sixty-second video chat, peer-to-peer through Daily dot co. The timer is server-enforced — at zero, the room closes and both users are returned to the feedback screen.

---

## Scene 7 — Post-Session Feedback (target 30 sec)

> Immediately after the session, both users rate the interaction independently: Like, Dislike, or Report. A mutual Like creates a match. Reports feed into the Trust Score system — a behind-the-scenes reputation layer that throttles bad actors without exposing the mechanism to users.

---

## Scene 8 — Matches + Chat (target 30 sec)

> Matched users land in the Matches tab, where they can continue the conversation via real-time Firestore messaging. The chat persists even after one or both users leave the app.

---

## Scene 9 — Safety (target 15 sec)

> Every screen keeps safety one tap away. In-session report, post-session report, and Matches tab block — all wired to the same moderation pipeline.

---

## Scene 10 — Closing (target 20 sec)

> Toodles. Built at CSU Fullerton. SwiftUI, Firebase, Daily dot co. Real people, real conversations, sixty seconds at a time. Thank you.

**Delivery:** slower than anywhere else. Full pauses between phrases.
