# Feedback Form Spec (Google Form)

**Title:** Toodles Pilot — Feedback (10 min app, 3 min form)
**Setup:** Google Form. Enable "Collect email addresses" (off by default) — you need it to track which invitees responded, but mark that field optional.
**Intro:** Paste the full text from `consent.md` into the form's description block.

## Questions (10 total, ordered low-to-high effort)

### 1. What device did you test on?
- Type: multiple choice (single answer)
- Options: iPhone (real) • Browser / Appetize • Other: _____

### 2. Did matchmaking work for you?
- Type: multiple choice
- Options: Yes, I matched with someone • Yes, but only with the demo peer pool • No — it spun forever • No — I got a "paused from matchmaking" screen • Other

### 3. On a 1–5 scale: how relevant was the match the algorithm picked?
- Type: linear scale 1 ("completely random") to 5 ("felt specifically for me")
- Only shown if Q2 is "Yes, I matched" or "Yes, demo peer"

### 4. Did the icebreaker prompt help?
- Type: multiple choice
- Options: Yes, it was what we ended up talking about • Yes, but we switched topics fast • Neutral — I barely noticed it • No, it felt canned • I refreshed it one or more times

### 5. Trust score — did the number feel meaningful or arbitrary?
- Type: multiple choice
- Options: Meaningful, I understood why it was what it was • Somewhat — I understood the direction but not the math • Arbitrary • I didn't notice a trust score • I saw the "rebuild your score" screen and engaged with it

### 6. How would you rate the post-call transcript?
- Type: multiple choice
- Options: Useful, I re-read it • Interesting but not useful • I didn't expand it • Felt fake / didn't match what we said • I got an error

### 7. Would you use this app for real if it launched?
- Type: multiple choice
- Options: Yes • Maybe if more people were on it • No, not my thing • No, concerns about safety/trust • No — other reason (explain below)

### 8. Biggest pain point or friction?
- Type: paragraph
- Placeholder: "Anything that annoyed you, confused you, or made you want to close the app — as specific as possible helps me most."

### 9. One thing you wish it did differently?
- Type: paragraph
- Placeholder: "Feature request, tone change, copy rewrite, anything."

### 10. May I paraphrase your answers in the capstone write-up?
- Type: multiple choice (required)
- Options: Yes, paraphrase freely • Yes, but anonymously only (don't name me) • No, keep my feedback private • Contact me first before quoting

## Post-form settings

- **Confirmation message:** "Thanks genuinely. This helps. — Danny"
- **Response summary:** off (don't auto-share summaries with respondents).
- **Edit after submit:** on (let people fix typos).
- **CSV export:** Danny downloads after 2026-05-10 close.

## Analysis plan (post-collection)

1. Pull CSV into a spreadsheet. One tab = raw responses.
2. Second tab: quantitative tallies for Q1-Q7.
3. Third tab: open-ended Q8/Q9 triaged into buckets (bug, feature, UX, copy, safety).
4. Pull 3-5 short paraphrases for the capstone report — respecting Q10 preferences.
