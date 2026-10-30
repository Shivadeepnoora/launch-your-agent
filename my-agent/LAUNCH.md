# Launch: repo-consistency-checker

Everything is resumable. Each script reads `IDS.env` and skips anything already created.

| Step | Command | What it does |
|---|---|---|
| 0 | put `ANTHROPIC_API_KEY=…` in `.env` (or `export` it) | Optional: `REPO_TOKEN=…` too, only if the repo is private (fine-grained, Contents: read-only) |
| 1 | `./launch.sh` | Picks a model → 📦 environment → 🤖 agent → ▶️ first run (session + 🎯 outcome kickoff) |
| 2 | `./watch.sh --wait` | Polls until the run finishes, prints the grader verdict, downloads outputs to `runs/<session>/` |
| 3 | `evals/run-evals.sh` | Held-back cases 02 and 03 on the pinned agent version → `evals/results-v<N>.json` |
| 4 | `./deploy.sh` then `./deploy.sh --run` | 🗓️ weekly deployment (Mon 08:00 Asia/Kolkata), then a manual test fire |
| any | `./launch.sh --new-run` | Another on-demand audit |

Apply a fix: `git apply runs/<session>/fix.patch`, run from the repo root after reading the report.

Console: https://platform.claude.com/workspaces/default/agents (if your key lives in a different workspace, switch with the picker).
