# Backup Plans — If Things Go Wrong

Quick reference for common failures. Triage faster, panic less.

## Appetize.io session dies mid-take

**Symptom:** screen freezes, "Session Ended" message, 10-min timer expires.

**Fix:**
1. Refresh the tab
2. Re-log-in with the test account
3. Retake the scene
4. If this happens >2×/day, upgrade to Appetize Enterprise Trial (~$40) — you lose less time than burning takes on free tier.

---

## Daily.co room fails to connect

**Symptom:** "Start Chatting" spins forever, or shows an error.

**Fix:**
1. Check Firebase Cloud Functions logs for the Trust Gate call
2. Confirm `DAILY_CO_API_KEY` env var is set on the Cloud Function
3. Confirm both test accounts have `trust_score ≥` the Trust Gate threshold
4. Confirm you haven't hit Daily.co's free tier room-minute cap
5. Last resort for the demo recording only: hardcode a valid room token in the app, record, then revert. **Do not ship this.**

---

## Firebase free-tier quota exceeded

**Symptom:** Firestore writes fail, Cloud Functions return 429.

**Fix:**
1. Firebase Console → Usage → identify which service capped
2. Rehearse with ONE account, only use both for actual takes
3. Consider upgrading to Blaze (pay-as-you-go) — at demo scale, costs pennies

---

## Voice-over sounds amateur

**Symptom:** echo, room noise, mouth clicks.

**Fix, in order of effort:**
1. Re-record in a closet with clothes on hangers around you (cheapest sound booth you can make)
2. Audacity: Effect → Noise Reduction (stronger settings) → Compressor → Normalize
3. Try `audiodenoise.com` (free, browser-based, works well)
4. Last resort: AI voice via ElevenLabs free tier. **Note:** faculty can often tell — use only if your own voice is unsalvageable.

---

## Compositing looks fake in Scene 6

**Symptom:** stock footage is obviously pasted on top of the app UI.

**Fix:**
1. Shorten each stock clip to 3–4 sec max before cutting to another angle — quick cuts hide imperfections
2. Add motion blur (CapCut → Effects → Blur → Motion Blur, 0.3)
3. Color-match with Auto Color on the stock clip
4. **Best fix:** embrace the placeholder. Use the transparent Scene 6 VO line:
   > *"In this test environment, user video is represented with placeholder tiles. The production app streams real peer-to-peer video via Daily.co."*
   Honest, grades fine for capstone, **and actively helps your Accountability/Transparency rating per the professor's Sprint 4 email**.

---

## Exported MP4 too big

**Symptom:** Canvas rejects >500 MB, or YouTube upload crawls.

**Fix:**
1. CapCut Export → Bitrate → Recommended (not Higher)
2. Re-export 1080p30 instead of 1080p60 — file halves, barely visible for a static-UI demo
3. Use HandBrake (free, Windows) to transcode to H.265

---

## Video runs long (>5:00)

**Fix, cut in this order:**
1. Scene 4 Profile → 15 sec
2. Scene 9 Safety → 10 sec
3. Scene 8 Matches → 20 sec
4. Tighten all transitions 0.3 → 0.2 sec

**Never cut:** Scene 1 (cold open), Scene 6 (video chat). Those are load-bearing.

---

## Video runs short (<3:00)

**Fix:**
1. Extend Scene 6 with additional angles on the composited stock video
2. Add a 20-sec "Challenges + Learnings" scene between 9 and 10 — title card + voice-over covering 2–3 things you learned. This scene is a gift for Creativeness and Completeness peer ratings.

---

## Last resort — demo pipeline collapses on submission day

If on deadline day Appetize, Firebase, or CapCut is all broken:

1. **Narrated Figma / wireframe walkthrough.** Obviously lower production value but acceptable with honest framing: *"Our recording environment failed at X; here is the UX walkthrough supplementing our written report."* CPSC faculty have seen this before.
2. Rank this as outcome 5/10 vs. 8/10 for a recorded demo. Avoid if possible, but know it exists.
