# Toodles v1.1 Informal Pilot

**Dates:** 2026-05-05 through 2026-05-10 (6-day window).
**Target:** 6–10 participants, friends-and-family only. CSUF-adjacent when possible but not exclusively.
**Classification:** **Informal feedback study.** Not an IRB-sanctioned pilot — do not call it a "CSUF study" in the final report. The `docs/superpowers/specs/2026-04-22-toodles-v1.1-roadmap-design.md` spec sets this framing deliberately.

## Why informal and not formal

A sanctioned CSUF pilot requires IRB-lite consent processes, participant recruitment via approved channels, and review timelines that don't fit the 3-week window before semester close. The informal version trades statistical weight for speed while staying honest in the write-up.

## Files in this directory

| File | Purpose |
|---|---|
| `recruit-template.md` | iMessage / SMS copy for inviting participants |
| `consent.md` | Plain-language disclaimer participants see before their first session |
| `feedback-form.md` | 10-question Google Form spec to hand to participants after their session |
| `analytics-events.md` | Event spec for the client (not yet implemented — v1.2 scope) |
| `report-copy.md` | Honest framing for the final report's pilot section |

## Running the pilot

1. **Day -2 (2026-05-03):** Send the invite from `recruit-template.md` to 10 people you know. Aim for 8 confirms.
2. **Day -1 (2026-05-04):** Create the Google Form from `feedback-form.md`. Shorten the link. Note the edit URL for yourself.
3. **Day 1 (2026-05-05):** Open the pilot. Send the TestFlight or Appetize link. Answer questions as they come up but don't prime.
4. **Days 2–5:** Participants test on their own time. Soft-nudge the quiet ones on day 4.
5. **Day 6 (2026-05-10):** Close the form. Export CSV. Triage feedback into must-fix / nice / v1.2.

## Hard rules

- **No deception.** If someone asks "is this a real dating app?" — no, it's a capstone project, yes their data will be deleted by 2026-05-31.
- **No quoting without permission.** Paraphrase in the final report unless the participant explicitly OKs a direct quote.
- **Participants are not subjects.** They're testers doing you a favor. Thank them properly.
