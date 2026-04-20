# Appetize.io Setup

Goal: two iPhone simulators running Toodles side-by-side in Chrome, logged in as two different test accounts, ready to record split-screen.

## Test accounts (do once, before recording day)

Create two CSU Fullerton accounts that pass the Trust Gate:

| Account | Email | Password | Profile |
|---|---|---|---|
| A | `testuser1@csu.fullerton.edu` | *(store in password manager)* | "Alex", Sophomore, prompt filled, profile photo uploaded |
| B | `testuser2@csu.fullerton.edu` | *(store in password manager)* | "Jordan", Junior, prompt filled, profile photo uploaded |

If you don't have two real `@csu.fullerton.edu` addresses available, seed them in your Firebase test environment — or ask a classmate to lend theirs for the seed. **Don't** route auth around the domain check; the whole point of Scene 3 is showing that check working.

Both accounts need:
- `trust_score ≥` your Trust Gate threshold (check in Firestore)
- `profile_complete = true`
- Not blocked or reported
- A real-looking profile photo (Pexels "portrait professional" search has free CC0 headshots)

## Chrome window layout

1. Open **Chrome Window A** (`Ctrl+N`)
2. Navigate to your Appetize.io app URL
3. Launch the Toodles build, log in as `test_user_1`
4. Resize to **960×1080**, dock to LEFT half (**Win+Left**)

5. Open **Chrome Window B** — use **Incognito** (`Ctrl+Shift+N`) so Appetize session cookies don't collide with Window A
6. Navigate to Appetize.io app URL
7. Launch Toodles, log in as `test_user_2`
8. Resize to **960×1080**, dock to RIGHT half (**Win+Right**)

**Tip:** once both windows are positioned, take a screenshot of the layout. If Chrome crashes mid-session, you can restore quickly.

## Appetize session notes

- **Free tier:** ~100 minutes/month. A 4-hour recording day will burn it fast.
- **Paid tier:** Enterprise Trial is ~$40/mo and gives 30 hours + audio passthrough. Worth it for demo week.
- Sessions auto-time-out after ~10 min of inactivity. Keep the tab active by interacting periodically.
- If a session dies mid-take: refresh the tab, re-log-in, retake the scene, move on.

## Pre-flight checklist (before pressing record)

- [ ] Both Chrome windows visible, no overlap, no taskbar blocking either phone frame
- [ ] Both Toodles apps on the home screen, logged in
- [ ] OBS running in the background, test recording already verified working
- [ ] Chrome notifications **disabled** (Settings → Privacy → Site Settings → Notifications → block all)
- [ ] Windows notifications **silenced** (Focus Assist: Priority only OR Alarms only)
- [ ] Taskbar clock widget hidden OR cropped out of OBS capture
- [ ] Appetize session timer shows **>8 min remaining** on both windows
- [ ] Mouse cursor parked off-screen before starting recording
