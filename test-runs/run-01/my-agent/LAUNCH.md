# Launching tiny-tots-rhymes-weekly

Everything runs from this folder. Your key lives in `.env`, which only you can read and git ignores. IDs are saved to `IDS.env` as they're created, so any step can be re-run safely.

| Step | Command | What it does |
|---|---|---|
| Launch | `./launch.sh` | Picks the newest Opus-class model → creates 📦 environment → 🧠 memory store → 🤖 agent → ▶️ first run (🎯 outcome kickoff) |
| Watch | `./launch.sh status` | Status, grader verdict and usage of the latest run |
| Fetch packs | `./launch.sh outputs` | Downloads the run's files into `out/<session_id>/` |
| Run again now | `./launch.sh run "manual run"` | A fresh run with the same task and checklist |
| Schedule | `./launch.sh deploy` | Creates the 🗓️ deployment: Sundays 18:00 Asia/Kolkata |
| Test the schedule | `./launch.sh deploy-run` | Fires the deployment once right now |
| Evals | `evals/run-evals.sh` | Runs each eval case against the pinned agent version |

Console: https://platform.claude.com/workspaces/default/agents (switch workspaces with the picker if your key isn't in the default one).
