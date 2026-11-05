# Launching hyd-website-outreach

Everything runs from this folder. The key comes from a non-empty `.env` (readable only by you, ignored by git) or from `ANTHROPIC_API_KEY` in your environment settings. IDs are saved to `IDS.env` as they're created, so any step can be re-run safely.

| Step | Command | What it does |
|---|---|---|
| Launch | `./launch.sh` | Checks `claude-opus-5-5` + `claude-sonnet-5-5` → 📦 environment → 🧠 2 memory stores (history, opt-outs) → 📄 custom skill → 🤖 researcher → 🤖 lead (with the researcher on its roster) → ▶️ first run (🎯 outcome kickoff, $8.00 budget) |
| Watch | `./launch.sh status` | Status, grader verdict and usage of the latest run |
| Fetch results | `./launch.sh outputs` | Downloads leads.csv, call-sheet.csv, outbox/ and demos/ into `out/<session_id>/` (after status is idle). Unsafe file names are renamed and demo pages are checked for scripts |
| Record an opt-out | `./launch.sh optout "Business" "Area" "email/phone"` | Adds them to `opted-out/` in the opt-out store (read-only to the agent); the agent never contacts them again |
| Run again now | `./launch.sh run "manual run"` | A fresh run with the same task and checklist |
| Schedule | `./launch.sh deploy` | Creates the 🗓️ deployment: weekdays 08:00 Asia/Kolkata |
| Test the schedule | `./launch.sh deploy-run` | Fires the deployment once right now |
| Evals | `evals/run-evals.sh` | Runs each eval case against the pinned agent version |

**Before sending any outbox email:** replace `{{AGENCY_NAME}}`, `{{SENDER_NAME}}`, `{{PHONE}}` and `{{DEMO_URL}}`, spot-check the contact's source link, and send from your own domain's address, never a personal inbox.

Console: https://platform.claude.com/workspaces/default/agents (switch workspaces with the picker if your key isn't in the default one).
