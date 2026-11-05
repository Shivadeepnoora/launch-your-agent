#!/usr/bin/env bash
# Run every eval case as its own session against the pinned agent version; collect verdicts.
# Each case folder may hold input.md (extra task context); expected.md is the known-good reference.
set -euo pipefail
cd "$(dirname "$0")/.."
# key: a non-empty .env wins; otherwise use ANTHROPIC_API_KEY from the environment (e.g. a cloud environment secret)
set -a; if [ -f .env ] && grep -q "^ANTHROPIC_API_KEY=." .env; then source .env; fi; [ -f IDS.env ] && source IDS.env; set +a
out="evals/results-v${AGENT_VERSION}.json"; echo "[]" > "$out"
for c in evals/case-*/; do
  name=$(basename "$c")
  ./launch.sh run "eval $name v$AGENT_VERSION" >/dev/null
  sid=$(tail -1 sessions.log)
  python3 - "$out" "$name" "$sid" <<'PY'
import json,sys; p,n,s=sys.argv[1:]; r=json.load(open(p)); r.append({"case":n,"session":s,"verdict":None}); json.dump(r,open(p,"w"),indent=2)
PY
  echo "$name -> $sid"
done
echo "Started. Check each with ./launch.sh status <session>; record verdicts in $out."
