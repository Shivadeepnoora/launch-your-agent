# Rubric: today's Hyderabad website-outreach leads

Grade each criterion pass/fail. All six must pass.

1. **10 new leads.** Exactly 10 Hyderabad businesses in the target categories (salons & spas, clinics & dentists, restaurants & cafes). None was already listed under `contacted/` (history store) or `opted-out/` (opt-out store) before this run, and the history store now has a `contacted/<slug>.md` entry for each of today's 10.
2. **Proof each one needs a website.** Each lead is classified as `no_website`, `social_only`, `aggregator_only`, `broken` or `not_mobile_friendly`, with source links for the business listing and for the website check. Businesses that already have a working, mobile-friendly site are not included.
3. **Only public business contacts.** Every email address and phone number is one the business itself publishes (its own page, profile or public listing), with a source link. No personal addresses and no data from behind logins. Leads without a public business email are in `call-sheet.csv`, not in the outbox.
4. **Honest personalised email.** Each `outbox/NN-email.send.json` matches the email.send schema (`to` with exactly one address, `subject`, `body_markdown`). The body is 150 words or fewer, names this business's specific gap, links `{{DEMO_URL}}`, includes no prices, uses `{{AGENCY_NAME}}`, `{{SENDER_NAME}}` and `{{PHONE}}`, has an honest subject line, and ends with a clear opt-out line.
5. **Truthful demo page.** Each lead has `demos/<slug>/index.html`: one mobile-friendly page (viewport meta tag present) using only the business's real public information, with the "Preview concept … not an official website" banner. No invented reviews, ratings, prices or claims, no copied logos or photos, and no scripts or event handlers.
6. **Lead sheet.** `leads.csv` lists all 10 with business, category, area, gap type, contact, source links and status (`email_draft` or `call_sheet`). `SUMMARY.md` gives the day's totals.
