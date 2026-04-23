# Analytics Events Spec — v1.2 Scope

These events are **specified** in v1.1 but **not implemented in code**. Shipping the instrumentation is scoped to v1.2. This document is the source of truth when wiring it up.

## Why defer instrumentation

- Real observability (Firebase Analytics, a custom Firestore events collection, or Amplitude) adds client-side complexity and a schema the pilot doesn't strictly need.
- Self-reported feedback (Google Form in `feedback-form.md`) gives higher-signal, lower-volume data for n≈8 participants.
- Instrumentation written for n=8 often over-fits and needs rewriting when n grows. Better to ship it after the pilot has shaped the real questions.

## Event list

| Event name | When it fires | Payload fields |
|---|---|---|
| `session_started` | User enters StartChattingView → trust check passes | `sessionIndex`, `source` (home/matches-tab) |
| `matchmaking_entered` | MatchmakingService.startSearching called | `uid`, `interestsCount`, `trustScore` |
| `match_found` | MatchmakingService.status transitions to .matched | `sessionID`, `partnerUID`, `matchScoreTotal`, `waitSeconds`, `mode` (mock/daily) |
| `match_fallback_to_demo` | 15s scan timed out | `uid`, `scanSeconds` |
| `session_ended` | MockVideoCallView.endCall | `sessionID`, `endReason` (timer/like/pass/report), `secondsRemaining` |
| `icebreaker_shown` | First appearance of IcebreakerPill | `sessionID`, `icebreakerID`, `category` |
| `icebreaker_refreshed` | User taps refresh button | `sessionID`, `newIcebreakerID`, `refreshCount` |
| `reported_peer` | User taps Report (mid-call or feedback) | `sessionID`, `partnerUID` (if live), `source` |
| `feedback_submitted` | PostSessionFeedbackView.submit | `sessionID`, `status` (matched/rejected/reported/ended), `wantsNext` |
| `trust_recovery_viewed` | TrustRecoveryView appears | `uid`, `currentScore` |
| `trust_recovery_task_claimed` | TrustRecoveryView.apply(task) succeeds | `uid`, `taskRawValue`, `newScore` |
| `transcript_expanded` | User taps the transcript section to expand | `sessionID`, `isSynthetic` |

## Implementation notes (for v1.2)

- **Transport:** write to `events/{eventID}` in Firestore with `{ name, ts, uid, payload }`. Later move to Firebase Analytics if event volume needs it.
- **Pseudo-anonymization:** no PII in payloads. Names, emails, photos — never. UIDs are fine (they're already the data-layer primary key).
- **Schema drift:** add a `schemaVersion: 1` field to every event. Bump on breaking changes.
- **Throttling:** if an event could fire >1/sec (not in this list, but defensively), debounce on the client.
- **Opt-out:** respect a `users/{uid}.analyticsOptOut` boolean at event time.
- **Retention:** 30 days for the informal pilot; 90 days for v1.2 proper. Set a Cloud Function cron to trim.

## What NOT to track

- The contents of messages or the transcript text. That's conversation data.
- The user's location. Not needed and not collected anywhere else.
- Who likes whom. The match status is already in `matches/`; don't duplicate via analytics.
- Any cross-user graph beyond the session boundary. No "user A viewed user B's profile 3 times this week" metrics — privacy over funnels.
