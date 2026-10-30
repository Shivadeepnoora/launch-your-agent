#!/usr/bin/env bash
# Golden-set pass: one session per case on the pinned AGENT_VERSION.
#   evals/run-evals.sh [case-02 case-03 ...]    default: the held-back cases
# Starts all sessions, waits for them, writes evals/results-v<N>.json with verdicts + cost.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"
cd "$DIR/evals"
CASES=("$@"); [ ${#CASES[@]} -eq 0 ] && CASES=(case-02 case-03)

declare -A SID
for c in "${CASES[@]}"; do
  patch=(); [ -f "$c/drift.patch" ] && patch=("$DIR/evals/$c/drift.patch")
  api POST /sessions "$(python3 "$DIR/cma.py" session "eval $c (v$AGENT_VERSION)" "${patch[@]}")"
  SID[$c]=$(get id); echo "▶️ $c ${SID[$c]}   $CONSOLE/sessions/${SID[$c]}"
done

for c in "${CASES[@]}"; do "$DIR/watch.sh" --wait "${SID[$c]}" | tail -n 3; done

OUT="results-v$AGENT_VERSION.json"
for c in "${CASES[@]}"; do api GET "/sessions/${SID[$c]}"; cp "$RESP" "/tmp/eval-$c.json"; echo "$c ${SID[$c]}"; done |
python3 - "$OUT" "$AGENT_VERSION" <<'PY'
import json, sys
out, ver, rows = sys.argv[1], sys.argv[2], []
for line in sys.stdin:
    case, sid = line.split()
    d = json.JSONDecoder(strict=False).decode(open(f"/tmp/eval-{case}.json").read())
    ev = d.get("outcome_evaluations") or [{}]
    rows.append({"case": case, "session": sid, "verdict": ev[-1].get("result"),
                 "explanation": ev[-1].get("explanation"), "cost_cents": (d.get("usage") or {}).get("list_cost"),
                 "outputs": f"runs/{sid}/"})
json.dump({"agent_version": int(ver), "cases": rows}, open(out, "w"), indent=2)
for r in rows: print(f"{r['case']:8} {r['verdict']}")
PY
echo "→ evals/$OUT  (compare each runs/<session>/report.md with evals/<case>/expected.md)"
