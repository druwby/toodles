# CapCut Desktop — Editing Guide

Day 3 work. Expect 4–6 hours end to end. **Save every 15 min (`Ctrl+S`).**

## Install

1. `capcut.com/tools/desktop-video-editor` → Windows download
2. Install → skip sign-in if possible

## New project

1. **New Project**
2. Timeline: **1920×1080**, FPS **60**, Aspect **16:9**
3. Save as `Toodles_Demo_Working.draft` in your work folder

## Import assets (drag into media panel)

- All `sceneNN_takeNN.mp4` files from OBS
- All `sceneNN.wav` voice-overs from Audacity
- All `card-X.png` title cards (screenshots from the HTML files in `title-cards/`)
- Both Pexels stock video clips for Scene 6 compositing

## Timeline layout

| Track | Contents | Purpose |
|---|---|---|
| V3 (top) | Title cards + Scene 6 compositing stock video | Overlays |
| V2 | Main app footage (Appetize recordings) | Core visual |
| V1 | Black backgrounds for intro/outro/gaps | Safety |
| A1 | Voice-over WAVs | Narration |
| A2 | Background music (optional, -24 dB) | Mood |

## Scene assembly (work left to right on timeline)

### 0:00–0:20 — Scene 1 Cold Open
- V2: black (Stickers → Background Colors → Black) for 20 sec
- V3: Toodles wordmark fade-in at 0:10 *(skip if no wordmark file exists)*
- A1: `scene01.wav`

### 0:20–0:35 — Scene 2 Tech Stack
- V2: black
- V3: `card-a-tech-stack.png` for 15 sec, 0.3 sec fade in/out
- A1: `scene02.wav`

### 0:35–1:00 — Scene 3 Auth
- V2: `scene03_takeNN.mp4` (best take)
- V3: `card-b-auth.png` full-slide cut for 2 sec at 0:48–0:50
- A1: `scene03.wav`

### 1:00–1:30 — Scene 4 Profile
- V2: `scene04_takeNN.mp4`
- A1: `scene04.wav`

### 1:30–2:10 — Scene 5 Matching
- V2: `scene05_split_takeNN.mp4`
- V3: `card-c-matching.png` full-slide cut for 2 sec at 1:42–1:44
- A1: `scene05.wav`

### 2:10–3:10 — Scene 6 Video Chat (NO COMPOSITING — 24-hr plan)
- V2: `scene06_takeNN.mp4` (single-session recording of the `MockVideoCallView` path)
- V3: `card-d-video-chat.png` full-slide cut at 2:14–2:16 (~2 sec)
- A1: `scene06.wav`

**What you're showing:** the app running in DEMO_MODE, which you built specifically for this situation. The mock video call view has a Tinder-dark UI (redesigned 2026-04-09). That IS the engineering feature — no compositing needed.

**If the mock view has black tiles or sparse visuals:**
- Zoom the recording slightly on the timer + UI chrome, which is the most visually interesting part
- Lean on Scene 6 voice-over to describe what's happening ("60 seconds, peer-to-peer via Daily.co, server-enforced timer")

**Optional — only if you have a full extra day:** fall back to the Pexels compositing approach described in `pexels-search-urls.md` and the older section of this guide. Not necessary for the 24-hour plan.

### 3:10–3:40 — Scene 7 Feedback
- V2: `scene07_takeNN.mp4`
- A1: `scene07.wav`

### 3:40–4:10 — Scene 8 Matches
- V2: `scene08_takeNN.mp4`
- A1: `scene08.wav`

### 4:10–4:25 — Scene 9 Safety
- V2: `scene09_takeNN.mp4`
- A1: `scene09.wav`

### 4:25–4:45 — Scene 10 Closing
- V2: black
- V3: `card-e-closing-credits.png` full-screen
- A1: `scene10.wav`
- Fade to black at 4:43

## Transitions

Keep it boring. Professional demos don't use spins or wipes.
- **Cross-dissolve 0.3 sec** between every scene
- Nothing else

## Audio cleanup

1. Select all VO clips → right-click → **Auto Enhance Speech: ON**
2. Listen through the whole timeline once with headphones
3. Re-import any VO that sounds muffled after auto-enhance

## Background music (optional, +1 hr)

Only if you have time.
- CapCut → Audio → Free → filter "corporate" or "technology"
- Preview 5–6 tracks → pick one that doesn't fight the voice
- Set A2 volume to **-24 dB** (quiet)
- Fade in at 0:00, fade out at 4:43

## Export settings

1. Top-right **Export**
2. Resolution: **1080p**, FPS **60**, Bitrate **Recommended** (Higher if file <500 MB)
3. Format: **MP4**, Codec: **H.264**
4. Save as `Toodles_CapstoneDemo_Final_YYYYMMDD.mp4`

## Before you upload

**Watch the exported file start-to-finish in a media player.** You will catch 1–2 things you missed. Re-export if anything is off. It takes 10 minutes and prevents the embarrassment of discovering a missing voice-over after the faculty has already clicked play.
