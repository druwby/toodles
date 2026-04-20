# EMERGENCY 24-HOUR PLAN

**Presentation:** Group 01, Tuesday 2026-04-21 at 7:00 PM, Zoom
**Today:** 2026-04-20 (~24 hrs until showtime)

This plan **replaces** the 3-day schedule in `../2026-04-20-demo-video-plan.md`.
Read this first. The other files are now reference material, not a walkthrough.

---

## What changed from the original plan

| Original 3-day plan | Emergency 24-hr plan |
|---|---|
| Split-screen two Appetize sessions | **Single Appetize session.** Voice-over handles the "two-user" framing. |
| Composite Pexels stock video in Scene 6 | **Record the app's own `MockVideoCallView`** — the Tinder-dark UI you built. No compositing. |
| 3+ takes per scene | **1–2 takes max.** Pick fastest clean run, move on. |
| Optional background music | **Skip music entirely.** Voice-over only. |
| Custom YouTube thumbnail | **Use YouTube's auto-generated thumbnail.** |
| Scene 4 Profile — 30 sec | **Cut Scene 4 to 15 sec** or drop entirely if running long |
| Multiple rehearsal passes | **One rehearsal per setup step.** |

Net effect: 13 hrs of work → ~8 hrs of work. Still tight, fits in 24 hrs with sleep.

---

## Timeline

### TONIGHT (Mon Apr 20) — target ~4 hrs

**T+0h — Install + accounts (45 min)**
- [ ] Install OBS Studio, Audacity, CapCut Desktop
- [ ] Verify the Toodles Appetize build loads in Chrome
- [ ] Confirm one test account `@csu.fullerton.edu` is logged in + has photo + passes Trust Gate
- [ ] If no test account exists, create one. Skip the second — single-session now.

**T+0:45 — Capture title cards (15 min)**
- [ ] Open each of the 5 HTML files in `title-cards/` in Chrome
- [ ] Press **F11** for full-screen
- [ ] **Win+Shift+S** → "full-screen snip" → save as `card-a.png` through `card-e.png`
- [ ] **Before capturing `card-e`:** edit it and fill in your 3 teammate names + roles (already pre-filled with Danny, Vincent, Chaitanya — verify roles, add a 4th if there's a teammate I don't know about)

**T+1:00 — Voice-over pass (1 hr)**
- [ ] Open `voice-over-scripts.md` — read all 10 scenes top to bottom once to warm up
- [ ] Record each scene in Audacity. **One take per scene unless it's truly bad.**
- [ ] Do the noise-reduction/compress/normalize cleanup listed in the VO file
- [ ] Export each as `scene01.wav` through `scene10.wav`

**T+2:00 — Appetize recording (1 hr)**
- [ ] OBS Display Capture configured, recording to `C:\Users\riven\Desktop\491project\_demo-recording\raw\`
- [ ] Windows Focus Assist ON, phone silenced, cursor parked off-screen
- [ ] Record scenes in this order (single-session; voice-over does the lifting):
  - [ ] Scene 3 — Auth (rejection + acceptance flow) — 1 take
  - [ ] Scene 4 — Profile edit — 1 take (skip if behind schedule)
  - [ ] Scene 5 — Home → Start Chatting → matching → room loaded — 1 take
  - [ ] Scene 6 — Mock video call screen, timer 60 → 0, auto-close — **2 takes**, pick best
  - [ ] Scene 7 — Post-session Like/Dislike/Report — 1 take
  - [ ] Scene 8 — Matches tab + in-app chat send/receive — 1 take
  - [ ] Scene 9 — Block/report modal from matches — 1 take
- [ ] Rename files `scene03_take01.mp4` etc. as you go

**T+3:00 — Backup + sanity check (30 min)**
- [ ] Copy raw files to a 2nd location (Google Drive, OneDrive, or USB)
- [ ] Open each MP4 briefly — no black frames, no corruption
- [ ] Sleep

### TOMORROW (Tue Apr 21) — target ~3.5 hrs

**T+0h (morning) — Import + assemble (1.5 hrs)**
- [ ] CapCut → new 1920×1080 / 60fps / 16:9 project, save as `Toodles_Demo.draft`
- [ ] Drag in: all raw scene MP4s, all scene WAVs, all title card PNGs
- [ ] Build timeline per `capcut-edit-guide.md` — **skip the Scene 6 compositing section entirely** (the mock video is already in the recording)
- [ ] Add 0.3 sec cross-dissolves between scenes. Nothing fancier.

**T+1:30 — Audio + review (1 hr)**
- [ ] Align each VO WAV to its scene's start
- [ ] Auto Enhance Speech on all VO clips
- [ ] Watch timeline start-to-finish with headphones
- [ ] Fix any misaligned VO / visible cursor / window border issue

**T+2:30 — Export + upload (45 min)**
- [ ] Export: 1080p / 60fps / H.264 / MP4 / Recommended bitrate
- [ ] Watch the exported MP4 end-to-end in a media player — catch anything you missed
- [ ] YouTube upload (unlisted), paste the metadata from `youtube-upload-metadata.md`
- [ ] Save the unlisted URL somewhere you won't lose it

**T+3:15 — Zoom rehearsal (15 min)**
- [ ] Open Zoom, start a test meeting with yourself
- [ ] Screenshare your browser with the YouTube video open, full-screen
- [ ] Enable "Share sound" and "Optimize for video clip" in Zoom's share options
- [ ] Play the video — verify audio + video reach the test Zoom participant (use a 2nd device if possible)

### SHOWTIME (Tue Apr 21, 7:00 PM)
- [ ] 6:45 PM — join the Zoom 15 min early. First group = first impression matters.
- [ ] 6:50 PM — pre-open YouTube video in browser, full-screen, audio tested
- [ ] 7:00 PM — intro yourselves (30 sec), share screen, play the 4:45 video, then 2 min of Q&A
- [ ] After: submit the YouTube URL wherever Canvas requires, plus the rating sheet for another group's earlier slot

---

## Scope cuts if you fall behind

Cut in this order:
1. **Skip Scene 4 Profile entirely** — saves 15 min of recording + 30 sec of runtime
2. **Skip Scene 9 Safety** — saves 10 min, mention safety in the Scene 7 VO instead
3. **Skip the Zoom rehearsal** if you really run out — risky but survivable
4. **NEVER cut** Scenes 1, 2, 5, 6, 7, 10 — those are the load-bearing ones

---

## Kyoung's email — what you still need to do **separately from the demo**

These do NOT block tomorrow's presentation, but Kyoung is grading them:

- [ ] **Peer rating sheet (Section 1)** — download from Canvas, rate Groups 02–05 (you watch them on Apr 21), then Groups 06–21 over the following week as their slots happen. Submit in original format, don't convert.
- [ ] **Group name** — still listed as "Pending." Pick a name tonight, email Kyoung.
- [ ] **Jira commit linkage** — your commits don't reference TDV ticket numbers. For Sprint 4 "Relevance" grading, next commits you make should look like `TDV-42: brief message here`. This won't retroactively fix past commits, but shows intent going forward.
- [ ] **Story Points + Priorities** — confirm every TDV ticket has both set. Kyoung is grading on these, not commit count.
- [ ] **Bulk-close timestamp issue** — all 7 critical tickets were updated within ~15 min on April 8. Nothing you can do about it now. If Kyoung asks, honest answer: "we reconciled Jira state after shipping the code — the commit history is the source of truth." Don't invent a cover story.

---

## One command to see everything at a glance

Print this file. Tape it next to your laptop. Work down the checklist. Don't read ahead.
