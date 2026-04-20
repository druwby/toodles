# Peer Rating Alignment — Per Professor's Sprint 4 Email

Kyoung's Sprint 4 email established **three peer rating aspects**:

1. **Creativeness of Approach**
2. **Completeness of Implementation**
3. **Overall Presentation Skill**

Plus five Sprint 2 criteria still in play:

- Accountability
- Traceability
- Transparency
- Separation of Duties
- Relevance

Below is how each scene of the demo deliberately scores against these.

---

## Scene-by-scene map

| Scene | Primary rating aspect | What it's doing for that rating |
|---|---|---|
| 1 — Cold Open | **Creativeness** | The "scroll/judge/ghost" framing positions Toodles against the existing market — shows we understood the *problem space*, not just coded to a spec |
| 2 — Tech Stack | **Completeness** | Listing the stack concretely proves we built each piece — not "planned to build" |
| 3 — Auth | **Completeness + Relevance** | Demonstrates a delivered requirement (domain-restricted auth per the PDF) |
| 4 — Profile | **Completeness** | Demonstrates another delivered requirement (profile editor + Storage upload) |
| 5 — Matching | **Completeness + Creativeness** | The Trust Gate → Cloud Function → Daily token pipeline is the *non-obvious* engineering work. Calling it out explicitly is a Creativeness signal. |
| 6 — Video Chat | **Transparency + Accountability + Completeness** | Honestly disclosing the stock footage (while showing the real room lifecycle and timer) turns a weakness into a rating-*positive* — it proves we know what we built vs. what we mocked. |
| 7 — Feedback + Trust Score | **Completeness + Creativeness** | Trust Score is a differentiator. Mentioning it briefly is enough — don't oversell. |
| 8 — Matches + Chat | **Completeness** | Demonstrates the real-time Firestore messaging we promised |
| 9 — Safety | **Completeness + Relevance** | Safety UX was a PDF promise. Shows we delivered it. |
| 10 — Closing | **Separation of Duties** | The roles-by-name credits list documents who did what — directly addresses the professor's Sprint 2 SoD criterion |

---

## The Scene 6 decision, explained

Kyoung wrote: *"focus on demonstration of your actual outcome, application"* and the Sprint 2 criteria include **Accountability, Traceability, Transparency**.

Originally the demo planned to composite stock video of two people chatting over the app's placeholder tiles. After inspecting the repo (2026-04-20), we found Danny had already built a `MockVideoCallView.swift` with a Tinder-dark UI specifically for the DEMO_MODE flag. That *is* the engineering outcome — the app has a deliberate demo path built in.

**Decision: record the MockVideoCallView as-is.** No compositing, no stock footage, no disclosure needed about faking. The primary VO in `voice-over-scripts.md` for Scene 6 now credits this as a deliberate engineering choice ("we built a mock video call view for test environments").

Why this is the strongest move:
- **Accountability:** we show what we actually built, including the demo path
- **Transparency:** no hidden compositing
- **Completeness:** the Daily SDK path exists and works on real hardware — we say so
- **Creativeness:** DEMO_MODE architecture is itself a creative engineering solution to a testing constraint

---

## What this demo deliberately does NOT do

- Does not claim AI moderation works (it's explicitly future work in the PDF — claiming it would hurt Traceability)
- Does not claim Like/Dislike/Report is 100% complete (PDF itself admits partial) — we show what works, narrate honestly
- Does not pad the runtime with unrelated feature ideas — scope discipline is itself a Relevance signal

---

## The closing credits and Separation of Duties

Kyoung grades on **Separation of Duties**. The roles-by-name closing credits aren't vanity — they're *evidence* for that criterion.

If some teammates contributed less than their role suggests, the honest approach is still generic-role labels ("Backend," "QA," "UX") rather than either inflated titles or a shorter credits list. Rationale:
- Inflated titles = poor Accountability
- Missing credits = could read as concealed SoD problems
- Generic labels = honest, non-inflammatory, professional

Fill those in `title-cards/card-e-closing-credits.html` before exporting.

---

## What you can tell the professor if asked

If Kyoung or a peer rater asks **"why is the Scene 6 video stock footage?"**, the honest answer (already scripted in the VO) is:

> "Our test environment uses browser-based iOS simulators, which don't support WebRTC camera passthrough. The underlying flow is live — Daily.co room, 60-second timer, room lifecycle — but the two video tiles are represented with stock footage. On a physical iOS device with native camera access, the peer video works as designed."

That answer maps directly to the Accountability + Transparency criteria. It's a demonstration of engineering maturity, not a confession.
