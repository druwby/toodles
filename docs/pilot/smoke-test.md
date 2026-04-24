# Appetize smoke test — v1.1

**Goal:** validate each v1.1 feature in ~5 minutes on Appetize before sending the pilot link.

## Setup (~60 seconds)

1. Download the `Toodles-simulator-app` artifact from the latest successful [iOS Build run](https://github.com/druwby/toodles/actions).
2. Unzip it — you'll get `Toodles.app`.
3. Go to <https://appetize.io> → Upload App → select `Toodles.app`.
4. Wait for Appetize to process it (~30s). Open the generated session in the browser.

## Checklist — walk through each screen

For each row, tap through the app and tick "Pass" if you see the expected behavior.

### Onboarding + profile
- [ ] **Signup** — Email/password signup with a `@csu.fullerton.edu` address completes, lands on profile setup.
- [ ] **Profile-complete gate** — the bio / photo / gender / show-me / interests fields all save. Continue button tappable after all required fields are set.

### v1.1 — matchmaking flow (TDV-82, TDV-81)
- [ ] **Trust check** — first tap on "Start Chatting" shows the "Verifying your trust score" scene briefly.
- [ ] **Match found** — the matchmaker either pairs you with another live Appetize user OR falls back to a `DemoPeer` after ~15s. Screen shows "Match found!" with the peer's name.
- [ ] **Shared-interests strip** — when you share any interests with the peer, the "You both like" pills render under the avatar on the match-found scene. (If this is a demo-fallback peer, this only appears when your profile has interests that overlap the DemoPeer — Emma Chen has Coffee/Hiking/Reading/Photography.)

### v1.1 — icebreaker (TDV-80)
- [ ] **Pill appears** — within the first second of the call, a glass "Icebreaker" pill fades in at the top of the call view.
- [ ] **Refresh works** — tapping the circular arrow icon on the pill swaps the prompt for a different one. Can do this up to 3 times; button disappears after.
- [ ] **Auto-hides at 12s** — pill fades out once 12s have elapsed (call timer shows 48s remaining).

### v1.1 — transcript (TDV-84)
- [ ] **Transcript appears on feedback screen** — after Like/Pass/Report on the call, the PostSessionFeedbackView shows a "Transcript" section under the feedback buttons.
- [ ] **"DEMO" pill is visible** — the section header shows a yellow `DEMO` pill since Appetize has no live mic, so the transcript is synthetic.
- [ ] **Expands with icebreaker as first turn** — tap to expand the transcript. The first line (speaker: You) is the exact icebreaker text the call used.

### v1.1 — trust recovery (TDV-83)
- [ ] **Trigger the blocked state** — manually set your user's `trust_score` to 30 in Firestore Console, then return to the app and tap Start Chatting. (Or: if you have a fresh test account, use the Support tab to send fake "report" feedback until the score drops.)
- [ ] **Blocked scene has Rebuild button** — the "Paused from matchmaking" screen shows a "Rebuild your score" primary button, not just "Go back."
- [ ] **Recovery tasks claim points** — tapping "Claim" on any task with its prerequisite satisfied (e.g. "Verify your CSUF email" if you signed up with a CSUF address) bumps the displayed score number and writes a `trustEvents/{id}` doc in Firestore.
- [ ] **Returns to matchmaking automatically** — closing the recovery view after clearing the 50-point threshold re-enters the trust check instead of the blocked state.

### v1.1 — tests (TDV-85)
- [ ] **CI unit tests pass** — the latest main run shows `✓ Run unit tests (Subprojects A/B/D/E)` green.

### Report-visible sanity checks
- [ ] **No Claude coauthor tag** — `git log --format=%b origin/main | grep -i "Co-Authored-By" | grep -i claude` returns empty.
- [ ] **Jira Development panel** — TDV-80 through TDV-86 each show PR #20 + the relevant commit under the "Development" sidebar.

## If anything fails

Report the failing row + the specific behavior you saw. Most issues will be either:
- **Missing data** — Firestore didn't return what was expected. Check the browser console (Appetize → ⋯ → Dev tools) for `[FirebaseFirestore]` errors.
- **Missing rules deploy** — matchmaking_queue / sessions / trustEvents writes fail with permission-denied if `firebase/firestore.rules` hasn't been pasted into Firebase Console → Firestore → Rules → Publish.
- **Stale Appetize session** — a full `.app` re-upload picks up CI builds faster than session refresh.
