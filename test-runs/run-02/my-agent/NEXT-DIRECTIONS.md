# Next directions: hyd-website-outreach

What the first version (v0) does: every weekday at 8:00 AM IST it finds 10 new Hyderabad salons and spas, clinics and dentists, or restaurants and cafes that need a website. It proves each gap with sources, builds a truthful demo page for each, drafts a personalised email with an opt-out line (to the outbox) for businesses with a public business email, and puts the rest on a call sheet. A 🧠 memory store makes sure no business is contacted twice.

## v1: send, publish, listen

### Send emails automatically via Bird
- **Why later:** needs a credential. You don't have an outreach domain yet, and automatic sending needs a domain verified in Bird with SPF, DKIM and DMARC records.
- **How:**
  1. Buy a domain and verify it in Bird (`domain.setup` flow).
  2. Store the Bird API key as a 🔐 vault `environment_variable` credential limited to Bird's API host.
  3. Add a custom `send_email` tool (or Bird's MCP server), gated `always_ask` for the first two batches, then `always_allow` with a daily cap of 10.
  4. Remove the outbox instruction. The outbox payloads (`to`, `subject`, `body_markdown`) map 1:1 onto the send call.
  5. Add Bird's suppression list to the opt-out check.
- **Before switching on:** warm the domain up gradually, and keep the opt-out line and STOP handling (below) in place first.

### Publish demo pages automatically and fill `{{DEMO_URL}}`
- **Why later:** needs a credential (GitHub Pages or Netlify).
- **How:** create a `demos` repo with GitHub Pages enabled and put a fine-grained token, scoped to that repo, in the vault. The agent pushes `demos/<slug>/index.html` and writes the published URL into each email.

### Process replies
- **Why later:** needs a credential (a Bird inbound address).
- **How:** a Bird inbound address sends replies by webhook to a session. A STOP reply writes `opted-out/<slug>.md` to the read-only opt-out store (through the agency's own webhook handler, never the agent); interested replies go to a daily "hot leads" summary for you.

## v2: follow up and see it all

### One polite follow-up
- **Why later:** planned for a later version.
- **How:** after 5 business days with no reply and no opt-out, send one short follow-up. `contacted/<slug>.md` already records the date and status. Never more than one follow-up.

### Lead dashboard (generated interface)
- **Why later:** planned for a later version.
- **How:** a small results viewer over the Files and Sessions APIs, showing leads, statuses, demo previews and reply rates.

## Always
- **Opt-outs are permanent.** Until v1 processes replies, add each STOP by hand: `./launch.sh optout "Business Name" "area" "email/phone"`. Opt-outs live in their own store, which the agent can read but not change.
- **Dynamic workflows are on.** The lead starts a workflow run only when one run must screen more than about 30 candidates. Every agent in a run uses tokens; the $8.00 per-run budget caps it. To turn them off, set `multiagent.workflows` to `{"type": "disabled"}` and update the agent.
- **Re-run evals before promoting a new agent version to the deployment.** Run `evals/run-evals.sh` and update the deployment only when the verdicts hold.
