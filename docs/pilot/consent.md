# Informal Pilot — Participant Disclaimer

**Show this to every participant before their first session.** Paste it into the Google Form as the intro block, and repeat the key bullets in the iMessage that shares the app link.

---

## Plain-language version (goes on the form and in the chat)

> Thanks for trying Toodles. A few things you should know before starting:
>
> - **This is a CSUF capstone project.** It's not a commercial product and it's not an IRB-sanctioned research study.
> - **Your account will be deleted by 2026-05-31.** Any photos, messages, or feedback you leave behind are wiped after that date.
> - **Your video stream is not recorded.** The v1.1 build uses a mock video view on the browser simulator (Appetize); on TestFlight the real video is peer-to-peer via Daily.co and also not recorded.
> - **Your feedback may be paraphrased in the capstone write-up.** No direct quotes without your permission. No screenshots including your face or name.
> - **If you're uncomfortable at any point, close the app.** If another participant does something that bothers you, tap the flag icon — the report is private and gets reviewed.
> - **Questions or concerns:** email dshtansky0@csu.fullerton.edu.
>
> By continuing, you acknowledge the above. Thank you genuinely — this helps my team a lot.

## What NOT to do with participant data

- Do **not** export raw Firestore dumps with emails or names into the write-up.
- Do **not** share the feedback CSV outside the capstone team.
- Do **not** keep any participant data past 2026-05-31. Set a calendar reminder.

## Data-deletion procedure (2026-05-31)

1. Firebase Console → Firestore → Delete collections: `users` (only pilot accounts), `matches`, `chats`, `supportTickets`, `matchmaking_queue`, `sessions`, `trustEvents`, `trustScores`.
2. Firebase Storage → delete profile photo bucket for pilot UIDs.
3. Firebase Authentication → Users tab → delete the pilot accounts.
4. Note the cleanup date in `docs/pilot/cleanup-log.md` (create when you do it).
