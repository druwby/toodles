# Toodles Capstone Demo Video — Production Plan

**Date:** 2026-04-20
**Owner:** Danny Shtansky (lead iOS dev + PM)
**Target length:** 4:30–4:45 (within CSUF 3–5 min requirement)
**Submission context:** CSUF CPSC 491 capstone showcase, high production value expected
**Format:** Polished product walkthrough (staged product demo, not live functional test)

---

## Strategic Decisions

**Approach:** Hybrid — real app captured on split-screen Appetize.io, with composited stock video over placeholder tiles during the 60-second video chat moment. Framed as a product walkthrough, which is standard industry practice (Apple, Google, Stripe all stage their keynote demos).

**Honesty posture:** The demo represents the *product experience* Toodles delivers in production. All UI, matchmaking, Firestore state sync, Daily.co room lifecycle, timer, and post-session feedback are real. The video tiles during peer chat are substituted with stock footage because Appetize.io does not support WebRTC camera passthrough — a test-environment limitation, not a product limitation.

**What we will NOT do:** Claim the demo is a live functional test. Use verbiage like "product walkthrough" or "product demo" in any written framing.

---

## Shot List (timeline)

| # | Timecode | Duration | Scene | Source |
|---|---------|----------|-------|--------|
| 1 | 0:00–0:20 | 0:20 | Cold open — problem statement | Title cards + voice-over |
| 2 | 0:20–0:35 | 0:15 | Tech stack card | Static slide |
| 3 | 0:35–1:00 | 0:25 | Auth: CSUF email gating | Appetize recording |
| 4 | 1:00–1:30 | 0:30 | Profile creation + photo upload | Appetize recording |
| 5 | 1:30–2:10 | 0:40 | Home screen → "Start Chatting" → matching | **Split-screen two Appetize sessions** |
| 6 | 2:10–3:10 | 1:00 | 60-sec video chat | **Split-screen + composited stock video** |
| 7 | 3:10–3:40 | 0:30 | Post-session Like / Dislike / Report + Trust Score | Split-screen Appetize |
| 8 | 3:40–4:10 | 0:30 | Matches list + 1:1 in-app chat | Appetize recording |
| 9 | 4:10–4:25 | 0:15 | Safety features (block/report modal) | Appetize recording |
| 10 | 4:25–4:45 | 0:20 | Closing — team credits + tech stack recap | Title cards |

Total: 4:45

---

## Voice-Over Script

### Scene 1 — Cold Open (0:00–0:20)

> "Dating apps train you to scroll, judge, and ghost. Toodles does the opposite. One tap connects you with a verified CSU Fullerton student for a sixty-second video chat. No profiles to polish. No messages to ignore. Just real conversations, sixty seconds at a time."

**Word count:** 45 words · **Target read time:** ~20 seconds at a natural pace (≈135 wpm)

**Delivery notes:**
- Beat 1 (*"Dating apps train you to scroll, judge, and ghost."*) — deliver flat and slightly weary; this is the indictment.
- Pause ~0.5 sec before *"Toodles does the opposite."* — let the contrast land.
- Pick the pace up through the middle; keep the two "No..." lines tight and parallel.
- Final line (*"Just real conversations, sixty seconds at a time."*) — slow down. This is the tagline.

**On-screen during this scene:** Black screen with the Toodles wordmark fading in around 0:10. No distracting B-roll. Let the voice carry it.

**Swap-in words if anything doesn't sound like you:**
- "scroll, judge, and ghost" → "swipe, judge, and ghost"
- "real conversations" → "real faces" / "real people"
- "CSU Fullerton" → "CSUF" (only if your normal speech shortens it; otherwise keep the full name — it sounds more deliberate in a capstone)

### Scene 2 — Tech Stack (0:20–0:35)

> "Toodles is built native for iOS using SwiftUI and Combine in the MVVM pattern. Authentication and data sync run on Firebase — restricted to verified university email domains. Video is peer-to-peer WebRTC through the Daily.co SDK, and server logic runs on Firebase Cloud Functions."

*(On-screen: stack logos — SwiftUI, Firebase, Daily.co — arranged clean.)*

### Scene 3 — Auth (0:35–1:00)

> "A student signs up with their CSU Fullerton email. Firebase Auth verifies the domain — non-university addresses are rejected at the boundary."

*(On-screen: show a `@gmail.com` rejection, then a successful `@csu.fullerton.edu` login.)*

### Scene 4 — Profile (1:00–1:30)

> "After verification, users build a lightweight profile — name, year, one prompt, one photo. Profile photos upload to Firebase Storage. The goal is minimal friction: you're here to talk, not to curate."

### Scene 5 — Matching (1:30–2:10)

> "From the home screen, one tap on 'Start Chatting' triggers the Trust Gate — a Cloud Function that verifies the user's standing and issues a Daily.co room token. Two users are matched into the same ephemeral room."

*(On-screen: **split-screen, both Appetize sessions**. User A taps Start Chatting; user B is already waiting. Both enter the room together. Show the Firestore presence sync if possible.)*

### Scene 6 — 60-Second Video Chat (2:10–3:10)

> "Here's the core Toodles experience: two verified students, one 60-second video chat, peer-to-peer through Daily.co. The timer is server-enforced — at zero, the room closes and both users are returned to the feedback screen."

*(On-screen: **split-screen with stock footage of two people chatting composited into each video tile**. The Toodles UI frame — timer counting down, mic/camera controls, report button — is real. Show the timer ticking from 0:58 → 0:03. Show the room auto-close at 0:00.)*

### Scene 7 — Post-Session Feedback (3:10–3:40)

> "Immediately after the session, both users rate the interaction independently: Like, Dislike, or Report. A mutual Like creates a match. Reports feed into the Trust Score system — a behind-the-scenes reputation layer that throttles bad actors without exposing the mechanism to users."

### Scene 8 — Matches + Chat (3:40–4:10)

> "Matched users land in the Matches tab, where they can continue the conversation via real-time Firestore messaging. The chat persists even after one or both users leave the app."

### Scene 9 — Safety (4:10–4:25)

> "Every screen keeps safety one tap away. In-session report, post-session report, and Matches-tab block — all wired to the same moderation pipeline."

### Scene 10 — Close (4:25–4:45)

> "Toodles — built at CSU Fullerton by [name teammates]. SwiftUI, Firebase, Daily.co. Real people, real conversations, sixty seconds at a time. Thank you."

*(On-screen: team names, course number CPSC 491, Spring 2026, GitHub link.)*

---

## Recording Setup

### Software (all free, Windows 10 compatible)

| Tool | Use | Notes |
|------|-----|-------|
| **OBS Studio** | Screen recording | Best-in-class free screen recorder. 1080p60, captures any browser window. |
| **Appetize.io** | iOS simulator in browser | Two sessions open in two separate Chrome windows, tiled side-by-side |
| **CapCut Desktop** | Video editing | Free, Windows-native, timeline editor. Easier learning curve than DaVinci. |
| **Audacity** | Voice-over recording | Free. Noise removal + compressor filter makes phone-mic quality acceptable. |
| **Canva** (free tier) | Title cards + tech stack slide | Or PowerPoint if you're faster in it. |
| **Pexels.com** | Stock video of two people chatting | Filter: Free license, Vertical or Portrait orientation, "video call" or "woman smartphone" searches. CC0, no attribution required. |

### Appetize split-screen recipe

1. Open Appetize.io in **two separate Chrome windows** (not tabs — windows can be positioned independently).
2. Resize each window so the iPhone frames sit side-by-side at roughly 540px wide each.
3. Launch the Toodles build on both simulators. Sign in as two different test accounts.
4. In OBS, create a **Display Capture** source covering the area that contains both phones.
5. Crop out the browser chrome (URL bar, Appetize UI) in OBS using source transforms.
6. Rehearse the matching → chat → feedback flow **5–7 times** before recording the final take. Aim for a clean sub-90-second run.

### Compositing stock video over placeholder tiles (Scene 6)

1. Record the full 60-sec room session with both Appetize sessions as-is — placeholders and all.
2. In CapCut, drop the recording on track 1.
3. Find two Pexels clips of people in a video-call-style close-up (one person each, looking roughly at camera). 45+ seconds long.
4. Drop each stock clip on tracks 2 and 3, positioned and scaled to cover the placeholder tiles exactly.
5. Feather the edges slightly (1–2px) so the composite doesn't look pasted.
6. Match the opacity or add a faint film grain to unify the look.
7. The Toodles UI frame (timer, buttons, borders) stays visible on top of the stock video — because it's in the original Appetize recording underneath.

### Voice-over workflow

1. Write the full script in one doc (use this file).
2. Record each scene as a separate Audacity project — easier to re-take.
3. Use your phone's Voice Memos app in a quiet room with a coat or blanket nearby for sound dampening, or any decent headset mic.
4. In Audacity: Effect → Noise Reduction (profile 6 sec of silence first) → Compressor (default settings) → Normalize to -1dB.
5. Export each scene as a separate WAV. Drop into CapCut's audio track. Align to shot cuts.

---

## Asset Checklist

- [ ] Two test accounts registered with `@csu.fullerton.edu` addresses
- [ ] Both accounts have profile photos uploaded
- [ ] Trust Score seeded high enough on both accounts that Trust Gate passes
- [ ] Daily.co API key active and in the Appetize build
- [ ] Firebase project quota healthy (not hitting free-tier limits during rehearsal)
- [ ] Two Chrome windows saved at correct size/position (bookmark the layout)
- [ ] 2 × Pexels video-call clips downloaded (45+ sec each, 1080p)
- [ ] Tech stack slide PNG exported (Scene 2)
- [ ] Team-credit closing slide PNG exported (Scene 10)
- [ ] Voice-over recorded for Scenes 2–10
- [ ] Cold-open VO recorded by Danny (Scene 1)
- [ ] Title cards between scenes (optional, but improves pacing)

---

## Production Schedule (suggested, ~3 days)

**Day 1 (4–5 hrs):**
- Write cold-open script (you)
- Record all voice-over in one session
- Download stock clips
- Create title cards in Canva

**Day 2 (4–5 hrs):**
- Set up OBS + two Appetize windows
- Rehearse matching flow until 3 clean takes
- Record: auth, profile, matching/chat, post-session, matches, safety
- Record multiple takes of each — discard in edit, don't re-record later

**Day 3 (4–6 hrs):**
- Edit in CapCut: assemble timeline per shot list
- Composite stock video for Scene 6
- Add voice-over, align to cuts
- Add title cards + transitions (keep transitions boring — cross-dissolve only, no spins)
- Color-correct if anything looks off
- Export 1080p60 H.264 MP4

**Buffer day:** One re-shoot pass for whatever looked weakest.

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Appetize session times out mid-record | Record in <10-min chunks; upgrade to paid tier for the demo week if needed (~$40) |
| Firebase quota exceeded during rehearsal | Use two project environments; switch if one caps |
| Daily.co room fails to create during final take | Pre-record 2–3 backup takes of Scene 6 on Day 2 |
| Voice-over sounds amateur | Re-record any scene >3× — first takes are always worst; take 4 is usually clean |
| Composite looks fake | Keep stock clips under 6 seconds visible before cutting away; don't give graders time to stare |
| Video exceeds 5 min | Cut Scene 4 (profile) first — it's the most skippable |

---

## Title Card Content (ready-to-paste)

These are the exact text contents for each title card / static slide. Open Canva or PowerPoint, use a clean dark-mode template (e.g. Canva's "Tech Startup" or a plain 1920×1080 black background), paste the text below, export as PNG, drop into CapCut.

---

### Card A — Tech Stack (Scene 2, displayed 0:20–0:35)

**Layout:** Centered title, three-row stack below, logos on each row if easy.

```
Built With


iOS   ·   SwiftUI   ·   Combine

Firebase Auth   ·   Firestore   ·   Storage   ·   Cloud Functions

Daily.co   —   Peer-to-Peer WebRTC Video


MVVM Architecture
```

**Style notes:** White text on near-black background (#0a0a0a). One accent color for the row separators — suggest Toodles brand color if you have one, otherwise a warm coral (#ff6b6b) reads well for a dating app.

---

### Card B — Auth Demo Banner (Scene 3, overlay at 0:35)

A small lower-third banner that appears briefly while the auth scene plays. Optional but adds polish.

```
Firebase Auth  ·  Domain-restricted to @csu.fullerton.edu
```

---

### Card C — Matching Pipeline Banner (Scene 5, overlay at 1:30)

```
Trust Gate  →  Cloud Function  →  Daily.co Room Token
```

---

### Card D — 60-Second Chat Banner (Scene 6, overlay at 2:10)

```
Daily.co  ·  Peer-to-Peer WebRTC  ·  60-second room lifecycle
```

---

### Card E — Closing Credits (Scene 10, displayed 4:25–4:45)

**Layout:** Large wordmark at top, team block in middle, metadata at bottom.

```
Toodles
Real people. Real conversations. Sixty seconds at a time.


Built by:
Danny Shtansky          —   iOS Lead · Product Manager
[Teammate 2 Name]       —   [Role]
[Teammate 3 Name]       —   [Role]
[Teammate 4 Name]       —   [Role]


CPSC 491 Capstone   ·   California State University, Fullerton   ·   Spring 2026

github.com/druwby/toodles


Thank you.
```

**TODO (Danny):** Fill in teammate names and roles before export. If some teammates did less than pulled weight, a generic role label ("Backend," "UX," "QA") keeps it professional without overclaiming. You don't owe anyone inflated credit on a rescue submission, but you also don't want to create drama at the finish line — use your judgment.

**Style notes:** Same color palette as Card A. Team block uses a monospaced or semi-monospaced font for clean alignment. The "Thank you." should be the last thing that fades to black.

---

## Definition of Done

- Final MP4 is 4:00–5:00 long
- 1080p minimum, 60fps preferred
- Audio is -16 to -12 LUFS integrated (normal for voice content)
- All 10 scenes present, voice-over clean, no dead air >1 sec except intentional beats
- Cold-open script written by Danny and recorded in his voice
- File named `Toodles_CapstoneDemo_Final_YYYYMMDD.mp4`
- Uploaded to unlisted YouTube + shared link archived in the submission folder
