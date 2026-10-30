#!/usr/bin/env bash
# Resumable launch: each step skips if its ID is already in IDS.env.
#   ./launch.sh            model → environment → agent → first run (session + outcome kickoff)
#   ./launch.sh --new-run  start another run on the same agent version
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if [ -z "${MODEL:-}" ]; then
  api GET /models
  python3 "$DIR/cma.py" pick-model "$RESP" > "$RESP.m"; save_id MODEL "$(cat "$RESP.m")"
fi
echo "model        $MODEL"

if [ -z "${ENV_ID:-}" ]; then
  api POST /environments @"$DIR/environment.json"; save_id ENV_ID "$(get id)"
fi
echo "✅ 📦 environment $ENV_ID"

if [ -z "${AGENT_ID:-}" ]; then
  api POST /agents "$(python3 "$DIR/cma.py" agent)"
  save_id AGENT_ID "$(get id)"; save_id AGENT_VERSION "$(get version)"
fi
echo "✅ 🤖 agent $AGENT_ID (v$AGENT_VERSION, $MODEL)   $CONSOLE/agents/$AGENT_ID"

if [ -z "${SESSION_ID:-}" ] || [ "${1:-}" = "--new-run" ]; then
  api POST /sessions "$(python3 "$DIR/cma.py" session "weekly audit (manual, v$AGENT_VERSION)")"
  sed -i.bak '/^SESSION_ID=/d' "$DIR/IDS.env" && rm -f "$DIR/IDS.env.bak"
  save_id SESSION_ID "$(get id)"
fi
echo "✅ ▶️ run started $SESSION_ID   $CONSOLE/sessions/$SESSION_ID"
