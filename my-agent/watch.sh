#!/usr/bin/env bash
# ./watch.sh [SESSION_ID]: one status line; with --wait, polls every 30s until idle/terminated,
# then downloads outputs into runs/<session>/.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
WAIT=0; [ "${1:-}" = "--wait" ] && { WAIT=1; shift; }
SID=${1:-$SESSION_ID}

status() {
  api GET "/sessions/$SID"
  python3 - "$RESP" <<'PY'
import json, sys
d = json.JSONDecoder(strict=False).decode(open(sys.argv[1]).read())
ev = [(e.get("result"), (e.get("explanation") or "")[:300]) for e in d.get("outcome_evaluations", [])]
print(d["status"], "| evaluations:", ev or "none yet", "| cost cents:", (d.get("usage") or {}).get("list_cost"))
PY
}

line=$(status); echo "$(date +%H:%M:%S) $line"
while [ $WAIT = 1 ] && [[ $line != idle* && $line != terminated* ]]; do
  sleep 30; line=$(status); echo "$(date +%H:%M:%S) $line"
done

if [[ $line == idle* || $line == terminated* ]]; then
  mkdir -p "$DIR/runs/$SID"
  api GET "/files?scope_id=$SID"
  python3 -c "import json,sys; [print(f['id'], f['filename']) for f in json.JSONDecoder(strict=False).decode(open(sys.argv[1]).read())['data']]" "$RESP" |
  while read -r fid fname; do
    curl -sS "$BASE/files/$fid/content" "${H[@]}" -o "$DIR/runs/$SID/$(basename "$fname")"
    echo "⬇️  runs/$SID/$(basename "$fname")"
  done
fi
