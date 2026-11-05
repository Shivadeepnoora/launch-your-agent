# Next directions: repo-consistency-checker

v0 ships first: a weekly read-only audit that produces report.md + fix.patch. Each later version below adds one thing.

## v1
### 1. Only report *new* drift
- **What:** the agent remembers findings you've accepted or deferred, so the Monday report only shows what changed.
- **Why later:** possible today; left out of v0 to keep it small.
- **How:** create a 🧠 memory store (`POST /v1/memory_stores`, `{"name":"consistency-findings"}`) and add `{"type":"memory_store","memory_store_id":"…","access":"read_write"}` to the deployment's `resources`. Add one line to `system`: "read /mnt/memory/consistency-findings/accepted.md first; append new accepted items when told." Docs: https://platform.claude.com/docs/en/managed-agents/memory

### 2. Deliver the report somewhere you'll see it
- **What:** the report lands as a GitHub issue (or a Slack message) instead of a file you fetch.
- **Why later:** needs a write credential that isn't on hand.
- **How:** add the GitHub MCP server `{"type":"url","name":"github","url":"https://api.githubcopilot.com/mcp/"}` plus an `mcp_toolset` with an `always_ask` policy, and store a fine-grained token (Issues: write) as a 🔐 vault `static_bearer` credential. Pass `vault_ids` on the deployment. Docs: https://platform.claude.com/docs/en/managed-agents/github

## v2
### 3. Open fix.patch as a pull request
- **What:** the agent pushes a branch and opens the PR itself.
- **Why later:** it's a write-action, so wait until a few weeks of patches have applied cleanly.
- **How:** use the same GitHub MCP with `always_ask`, and a token with Contents and Pull requests write scope on the repo resource. Tell the agent in `system` to branch as `consistency/<date-of-run>`.

### 4. Run on every push to `main`
- **What:** the audit runs on every merge, not just Mondays.
- **Why later:** possible today, but it's a second trigger and the weekly one comes first.
- **How:** add a GitHub Action on `push: main` that runs `curl -X POST -d '{}' https://api.anthropic.com/v1/deployments/$DEPLOYMENT_ID/run?beta=true -H "x-api-key: ${{ secrets.ANTHROPIC_API_KEY }}" -H "anthropic-version: 2023-06-01" -H "anthropic-beta: managed-agents-2026-04-01"`.

## Always
- **Re-run `evals/` before promoting any new agent version to the deployment:** `evals/run-evals.sh case-01 case-02 case-03` against the new version, and update the deployment's pinned `agent.version` only when the verdicts hold.
