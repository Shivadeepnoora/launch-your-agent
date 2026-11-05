# Next directions: tiny-tots-rhymes-weekly

What the first version (v0) does: every Sunday at 6:00 PM IST it writes 3 nursery-rhyme story packs (script, title, description, tags, thumbnail prompt and a drawn thumbnail mockup) as output files. A memory store keeps rhymes and angles from repeating.

## v1: delivery and voice

### Deliver packs to Google Drive (or as an email)
- **Why later:** needs a credential (a Google OAuth connection) that isn't set up yet.
- **How:** add the Google Drive MCP server to `agent.json` → `mcp_servers`, create a 🔐 vault with an `mcp_oauth` credential for it, and pass `vault_ids` on the deployment. Gate the Drive toolset `always_ask` for the first few weeks.
- **Docs:** https://platform.claude.com/docs/en/managed-agents/overview (MCP connectors, vaults)

### Voiceover audio per script
- **Why later:** needs a credential (a text-to-speech API key).
- **How:** store the key as a vault `environment_variable` credential, with limited networking to the TTS host. The agent calls the API from bash and saves `narration.mp3` in each pack.

## v2: production and growth

### Rough-cut video per pack
- **Why later:** planned for a later version. It needs an image-generation credential and video tooling.
- **How:** add an image-generation API key to the vault and `ffmpeg` to the environment packages (`apt`). The agent renders scene images and stitches them with the voiceover and captions into a review `.mp4`.

### Upload to YouTube as private drafts
- **Why later:** needs a credential (YouTube Data API OAuth). It's also a write action, so it stays behind your approval.
- **How:** a custom tool or MCP server for `videos.insert` plus a vault credential, gated `always_ask`. Upload as **private** and **made for kids**; you review and publish.

### Learn from channel analytics
- **Why later:** needs a credential (YouTube Analytics read access).
- **How:** a vault credential for the Analytics API. The agent writes a weekly "what worked" note (top rhymes, titles, retention) into the 🧠 memory store and favours what performs.

## Always
- **Re-run evals before promoting a new agent version to the deployment.** Run `evals/run-evals.sh` against the new version and update the deployment only when the verdicts hold.
