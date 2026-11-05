#!/usr/bin/env bash
# Create the weekly scheduled deployment (Mon 08:00 Asia/Kolkata) on the pinned agent version.
#   ./deploy.sh         create (skips if DEPLOYMENT_ID exists), print upcoming runs
#   ./deploy.sh --run   fire a manual run now
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if grep -nE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "$DIR/first_prompt.txt"; then
  echo "literal date in first_prompt.txt: the deployment replays it every week; use relative dates" >&2; exit 1
fi

if [ -z "${DEPLOYMENT_ID:-}" ]; then
  api POST "/deployments?beta=true" "$(python3 "$DIR/cma.py" deployment)"
  save_id DEPLOYMENT_ID "$(get id)"
  echo "upcoming runs:"; get schedule.upcoming_runs_at
fi
echo "✅ 🗓️ deployment $DEPLOYMENT_ID   $CONSOLE/deployments/$DEPLOYMENT_ID"

if [ "${1:-}" = "--run" ]; then
  api POST "/deployments/$DEPLOYMENT_ID/run?beta=true" '{}'
  cat "$RESP"; echo
fi
