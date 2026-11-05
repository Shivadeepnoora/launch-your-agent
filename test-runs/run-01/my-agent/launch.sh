#!/usr/bin/env bash
# Resumable launch for tiny-tots-rhymes-weekly.
# Usage: ./launch.sh [all|model|env|memory|agent|run|status|outputs|deploy|deploy-run]
# Each step reads IDS.env first and skips objects that already exist; new IDs are appended at once.
set -euo pipefail
cd "$(dirname "$0")"
# key: a non-empty .env wins; otherwise use ANTHROPIC_API_KEY from the environment (e.g. a cloud environment secret)
set -a; if [ -f .env ] && grep -q "^ANTHROPIC_API_KEY=." .env; then source .env; fi; [ -f IDS.env ] && source IDS.env; set +a
: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY (environment secret or export) or put it in .env}"

BASE=https://api.anthropic.com/v1
CORE=(-H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json")
H=("${CORE[@]}" -H "anthropic-beta: managed-agents-2026-04-01")
HMEM=("${CORE[@]}" -H "anthropic-beta: agent-memory-2026-07-22")

save() { echo "$1=$2" >> IDS.env; export "$1=$2"; echo "  saved $1=$2"; }
field() { python3 -c "import json,sys; d=json.JSONDecoder(strict=False).decode(open('$1').read()); print(d$2)"; }
call() { # call <out.json> curl-args...   -> prints HTTP code, fails on >=400
  local out=$1; shift
  local code; code=$(curl -sS -o "$out" -w '%{http_code}' "$@")
  if [ "$code" -ge 400 ]; then echo "HTTP $code:"; cat "$out"; echo; return 1; fi
}

step_model() {
  [ -n "${MODEL:-}" ] && { echo "model: $MODEL (from IDS.env)"; return; }
  call /tmp/models.json "$BASE/models?limit=100" "${CORE[@]}"
  local m; m=$(python3 - <<'PY'
import json
ids=[m["id"] for m in json.load(open("/tmp/models.json"))["data"]]
opus=[i for i in ids if "opus" in i]
print((opus or ids)[0])   # API lists newest first
PY
)
  echo "model: picked $m"; save MODEL "$m"
}

step_env() {
  [ -n "${ENV_ID:-}" ] && { echo "environment: $ENV_ID (exists)"; return; }
  call /tmp/env.json "$BASE/environments" "${H[@]}" -d @environment.json
  save ENV_ID "$(field /tmp/env.json "['id']")"
}

step_memory() {
  [ -n "${MEMSTORE_ID:-}" ] && { echo "memory store: $MEMSTORE_ID (exists)"; return; }
  if ! call /tmp/mem.json "$BASE/memory_stores" "${HMEM[@]}" -d @memory_store.json; then
    echo "retrying memory store create with the managed-agents beta header"
    call /tmp/mem.json "$BASE/memory_stores" "${H[@]}" -d @memory_store.json
  fi
  save MEMSTORE_ID "$(field /tmp/mem.json "['id']")"
}

step_agent() {
  [ -n "${AGENT_ID:-}" ] && { echo "agent: $AGENT_ID v${AGENT_VERSION:-?} (exists)"; return; }
  python3 - <<PY > /tmp/agent_send.json
import json; a=json.load(open("agent.json")); a["model"]="$MODEL"; print(json.dumps(a))
PY
  call /tmp/agent.json "$BASE/agents" "${H[@]}" -d @/tmp/agent_send.json
  save AGENT_ID "$(field /tmp/agent.json "['id']")"
  save AGENT_VERSION "$(field /tmp/agent.json "['version']")"
}

kickoff_event() { python3 - <<'PY' > kickoff.json
import json
json.dump({"type":"user.define_outcome","description":open("first_prompt.txt").read(),
  "rubric":{"type":"text","content":open("outcome.md").read()},"max_iterations":3}, open("kickoff.json","w"), indent=2)
PY
}

step_run() {
  local title=${1:-"run $(date +%F)"}
  kickoff_event
  python3 - <<PY > /tmp/sess_send.json
import json
ev=json.load(open("kickoff.json"))
print(json.dumps({"agent":{"type":"agent","id":"$AGENT_ID","version":int("$AGENT_VERSION")},
  "environment_id":"$ENV_ID","title":"$title",
  "resources":[{"type":"memory_store","memory_store_id":"$MEMSTORE_ID","access":"read_write",
                "instructions":"used-rhymes.md lists rhymes and story angles already used. Read it first; append this week's picks at the end."}],
  "initial_events":[ev]}))
PY
  call /tmp/sess.json "$BASE/sessions" "${H[@]}" -d @/tmp/sess_send.json
  local sid; sid=$(field /tmp/sess.json "['id']")
  save SESSION_ID "$sid"; echo "$sid" >> sessions.log
}

step_status() {
  call /tmp/s.json "$BASE/sessions/${1:-$SESSION_ID}" "${H[@]}"
  python3 - <<'PY'
import json
d=json.JSONDecoder(strict=False).decode(open("/tmp/s.json").read())
print("status:", d["status"])
for e in d.get("outcome_evaluations",[]): print("verdict:", e.get("result"), "-", (e.get("explanation") or "")[:400])
u=d.get("usage") or {}; print("usage:", {k:u[k] for k in u if k in ("input_tokens","output_tokens","list_cost","active_seconds")})
PY
}

step_outputs() {
  local sid=${1:-$SESSION_ID}; mkdir -p "out/$sid"
  call /tmp/files.json "$BASE/files?scope_id=$sid&limit=100" "${H[@]}"
  python3 - "$sid" <<'PY' > /tmp/files.tsv
import json,sys
for f in json.load(open("/tmp/files.json"))["data"]:
    print(f["id"], f.get("filename") or f["id"], sep="\t")
PY
  while IFS=$'\t' read -r fid name; do
    mkdir -p "out/$sid/$(dirname "$name")"
    curl -sS "$BASE/files/$fid/content" "${H[@]}" -o "out/$sid/$name"; echo "  $name"
  done < /tmp/files.tsv
}

step_deploy() {
  [ -n "${DEPLOYMENT_ID:-}" ] && { echo "deployment: $DEPLOYMENT_ID (exists)"; return; }
  if grep -Eq '20[0-9]{2}-[0-9]{2}-[0-9]{2}' first_prompt.txt; then echo "literal date in first_prompt.txt — fix before deploying"; exit 1; fi
  kickoff_event
  python3 - <<PY > deployment.json
import json
ev=json.load(open("kickoff.json"))
print(json.dumps({"name":"Tiny Tots Rhymes — weekly packs","agent":"$AGENT_ID","environment_id":"$ENV_ID",
  "resources":[{"type":"memory_store","memory_store_id":"$MEMSTORE_ID","access":"read_write"}],
  "initial_events":[ev],
  "schedule":{"type":"cron","expression":"0 18 * * 0","timezone":"Asia/Kolkata"}}, indent=2))
PY
  call /tmp/dep.json "$BASE/deployments?beta=true" "${H[@]}" -d @deployment.json
  save DEPLOYMENT_ID "$(field /tmp/dep.json "['id']")"
  field /tmp/dep.json ".get('schedule',{}).get('upcoming_runs_at')"
}

step_deploy_run() { call /tmp/run.json -X POST "$BASE/deployments/$DEPLOYMENT_ID/run?beta=true" "${H[@]}" -d '{}'; cat /tmp/run.json; echo; }

case "${1:-all}" in
  all) step_model; step_env; step_memory; step_agent; step_run "first run" ;;
  model) step_model ;; env) step_env ;; memory) step_memory ;; agent) step_agent ;;
  run) step_run "${2:-}" ;; status) step_status "${2:-}" ;; outputs) step_outputs "${2:-}" ;;
  deploy) step_deploy ;; deploy-run) step_deploy_run ;;
  *) echo "unknown step $1"; exit 1 ;;
esac
