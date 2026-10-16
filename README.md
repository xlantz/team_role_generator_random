# PMBA Airlines — Team Site

A small site for the team: a weekly role draft, a weekly team scorecard, and the team contract. The role draft and scorecard share one Supabase database, so everyone who opens the link sees the same current assignment and the same results — nothing is stored per-browser.

**Current team:** Delaney, Alex, Nancy, Laurent, Daniel (5 people, 5 roles + the Deviant).

## Pages

- **`index.html`** — Role Draft. Draws the five team roles (Team Leader, Facilitator, Scribe, Resource Investigator, Evaluator) plus the Deviant, and keeps an all-time tracker of who's held what.
- **`scorecard.html`** — Weekly Scorecard. A 7-category weighted check-in modeled on the team contract, with an anonymized team pulse and a week-over-week trend.
- **`contract.html`** — The team contract, read-only.

## File structure

```
index.html                   Role Draft page
scorecard.html               Weekly Scorecard page
contract.html                Team Contract page
assets/style.css             Shared styles for all pages
assets/supabase-config.js    Your Supabase URL + anon key go here
```

## One-time setup (already done, for reference)

1. Create a Supabase project.
2. Run `supabase-setup.sql` once in that project's SQL Editor. It creates three tables (`role_state`, `role_history`, `scorecard_responses`) and seeds the single starting row the Role Draft page needs to load. There's no draw history until the first draw.
3. Paste the project's URL and anon (public) key into `assets/supabase-config.js`.
4. Deploy this folder to GitHub Pages.

`supabase-setup.sql` isn't needed by the live site — it's only useful if you ever need to recreate the tables (new Supabase project, accidental table drop, etc.). Fine to keep off to the side rather than in the deployed folder.

## How the role draft stays fair

Each 5-draw cycle is a randomized Latin square: every member gets each of the five roles exactly once per cycle, in an order that's reshuffled fresh each cycle. The Deviant rotates through a separate shuffled queue of all five people, refilling once everyone's had a turn. Counts on the tracker are derived from the full draw history, not stored separately.

**Changing the team.** The team and role lists are the `MEMBERS` and `ROLES` arrays at the top of the script in `index.html` (and `MEMBERS` in `scorecard.html`). Keep the two lists the same length so every cycle is a clean rotation. If the saved cycle in the database doesn't match the current lists (for example, right after someone leaves), the page starts a fresh cycle for the current team and drops removed people from the Deviant queue. Older draws involving removed people or roles stay in the draw history as a record, but they no longer count in the tracker, and the cards stay blank until the next draw.

**Reset all data** wipes the shared history and counts for the whole team — everyone with the link, not just your device. It's protected by a PIN, set as `RESET_PIN` in `index.html`. That's a guard against accidental clicks, not real security: anyone who views the page source can read it.

## How the scorecard works

- The check-in "week" resets every **Tuesday at 10:00 PM Mountain Time** — hard-coded to that timezone, so it's the same real-world moment for everyone regardless of their device's clock or location. It isn't tied to the calendar week.
- **If someone doesn't submit before the reset, that week is simply skipped for them** — they're excluded from that week's average, not given a default/average score. This is the standard approach for pulse-style check-ins: a missing response usually isn't random (the people who skip are often the ones something's up with), so imputing an average would mask the exact signal the check-in exists to catch. The pulse always shows "X of 5 checked in" so low participation is visible rather than papered over.
- One check-in per person, per cycle — enforced both in the UI and at the database level, so two people submitting at once can't create duplicates.
- Categories, weights, and the 1/3/5 rubric live in the `CATEGORIES` array near the top of `scorecard.html`'s script — edit that array to change what's being measured. Old responses stay valid even if categories change later; they just won't have data for categories that didn't exist yet.
- The weighted score formula matches the team's raise-metric spreadsheet: `weighted % = Σ(weight × score ÷ 5)`, with the same color bands (≥85% green, 70–84% amber, <70% red).
- Results are always shown aggregated across whoever has checked in that week — never broken out by name.
- **One-time transition note:** responses submitted before this change used ISO-calendar-week labels (e.g. `2026-W37`). Those rows are untouched and still display correctly, just with their old label style, until enough new-format weeks (`2026-09-08`, etc.) accumulate around them on the trend chart.

## A note on access

There's no login. Anyone with the link can read and submit data — appropriate for a small trusted team, but worth knowing if the link ever gets shared more widely than intended.
