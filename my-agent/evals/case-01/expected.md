# Case 01: clean `main` (no setup patch). Build input.

Ground truth, verified by hand on 2026-10-30 against main @ d5d0ffb:

| Check | Expected |
|---|---|
| Mirror drift | All 3 pairs identical |
| Broken references | **2 broken**: `README.md:47` → `interview-to-config.md` (now `.claude/skills/launch-your-agent/references/interview.md`); `README.md:48` → `examples-bank.md` (now `.claude/skills/launch-your-agent/references/examples-bank.md`) |
| Validity | All JSON parses; both HTML files link overview.css, no `<style>` |
| Stale facts | Not judged against a fixed answer; the rubric checks sourcing |
| fix.patch | Present; corrects the two README rows; `git apply --check` passes |

False positives (e.g. flagging build-kit paths like `agent.json`, `LAUNCH.md`) count as a fail.
