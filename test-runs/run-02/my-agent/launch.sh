#!/usr/bin/env bash
# Resumable launch for hyd-website-outreach.
# Usage: ./launch.sh [all|model|env|memory|skill|worker|agent|run|status|outputs|optout|deploy|deploy-run]
# Each step reads IDS.env first and skips objects that already exist; new IDs are appended at once.
set -euo pipefail
cd "$(dirname "$0")"
# key: a non-empty .env wins; otherwise use ANTHROPIC_API_KEY from the environment (e.g. a cloud environment secret)
set -a; if [ -f .env ] && grep -q "^ANTHROPIC_API_KEY=." .env; then source .env; fi; [ -f IDS.env ] && source IDS.env; set +a
: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY (environment secret or export) or put it in .env}"

BASE=${ANTHROPIC_API_BASE:-https://api.anthropic.com/v1}   # override only for local dry-runs
case "$BASE" in https://*|http://127.0.0.1:*) ;; *) echo "refusing non-https API base: $BASE"; exit 1 ;; esac
API_VERSION=${ANTHROPIC_VERSION:-2026-10-21}            # per the live managed-agents docs (Nov 2026)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT              # mode 700
# the key goes to curl through a config file, never on the command line (visible in ps)
( umask 077; printf 'header = "x-api-key: %s"\n' "$ANTHROPIC_API_KEY" > "$TMP/auth.cfg" )
AUTH=(-K "$TMP/auth.cfg" -H "anthropic-version: $API_VERSION")
CORE=("${AUTH[@]}" -H "content-type: application/json")
H=("${CORE[@]}" -H "anthropic-beta: managed-agents-2026-04-01")
HMEM=("${CORE[@]}" -H "anthropic-beta: agent-memory-2026-07-22")   # memory-store calls: this header ALONE

save() { printf '%s=%q\n' "$1" "$2" >> IDS.env; export "$1=$2"; echo "  saved $1=$2"; }
clean() { tr -d '\000-\010\013-\037\177'; }   # strip terminal control characters from API text
field() { python3 -c "import json,sys; d=json.JSONDecoder(strict=False).decode(open('$1').read()); print(d$2)"; }
call() { # call <out.json> curl-args... ; fails loudly on HTTP >= 400
  local out=$1; shift; local code
  code=$(curl -sS -o "$out" -w '%{http_code}' "$@")
  if [ "$code" -ge 400 ]; then echo "HTTP $code:"; cat "$out"; echo; return 1; fi
}
slug() { python3 -c "import re,sys; print(re.sub(r'[^a-z0-9]+','-',' '.join(sys.argv[1:]).lower()).strip('-'))" "$@"; }

step_model() {   # lead = claude-opus-5-5, researcher = claude-sonnet-5-5; confirm both are available to this key
  [ -n "${MODEL:-}" ] && { echo "models: $MODEL + ${WORKER_MODEL:-?} (from IDS.env)"; return; }
  call "$TMP/models.json" "$BASE/models?limit=100" "${CORE[@]}"
  python3 - "$TMP/models.json" <<'PY'
import json,sys
ids={m["id"] for m in json.load(open(sys.argv[1]))["data"]}
missing=[m for m in ("claude-opus-5-5","claude-sonnet-5-5") if m not in ids]
if missing: sys.exit(f"not available to this key: {missing}")
PY
  save MODEL claude-opus-5-5; save WORKER_MODEL claude-sonnet-5-5
}

step_env() {
  [ -n "${ENV_ID:-}" ] && { echo "environment: $ENV_ID (exists)"; return; }
  call "$TMP/env.json" "$BASE/environments" "${H[@]}" -d @environment.json
  save ENV_ID "$(field "$TMP/env.json" "['id']")"
}

step_memory() {   # history store (agent read_write) + opt-out store (agent read_only; only ./launch.sh optout writes it)
  if [ -n "${MEMSTORE_ID:-}" ]; then echo "memory store: $MEMSTORE_ID (exists)"; else
    call "$TMP/mem.json" "$BASE/memory_stores" "${HMEM[@]}" -d @memory_store.json
    save MEMSTORE_ID "$(field "$TMP/mem.json" "['id']")"; fi
  if [ -n "${OPTOUT_STORE_ID:-}" ]; then echo "opt-out store: $OPTOUT_STORE_ID (exists)"; else
    call "$TMP/memo.json" "$BASE/memory_stores" "${HMEM[@]}" -d @memory_store_optouts.json
    save OPTOUT_STORE_ID "$(field "$TMP/memo.json" "['id']")"; fi
}

step_skill() {   # upload skills/website-outreach as a custom skill (multipart files[], dir prefix in filename)
  [ -n "${SKILL_ID:-}" ] && { echo "skill: $SKILL_ID (exists)"; return; }
  local args=()
  while IFS= read -r f; do args+=(-F "files[]=@skills/$f;filename=$f"); done \
    < <(cd skills && find website-outreach -type f ! -name '*.pyc' | sort)
  if call "$TMP/skill.json" "$BASE/skills" "${AUTH[@]}" "${args[@]}" \
     || call "$TMP/skill.json" "$BASE/skills" "${AUTH[@]}" -H "anthropic-beta: skills-2025-10-02" "${args[@]}"; then
    save SKILL_ID "$(field "$TMP/skill.json" "['id']")"
  else
    echo "skill upload rejected - continuing without it (the system prompt carries the core procedure)"
  fi
}

step_worker() {   # the researcher subagent (no multiagent of its own: one level of delegation only)
  [ -n "${WORKER_ID:-}" ] && { echo "researcher: $WORKER_ID (exists)"; return; }
  python3 - "${SKILL_ID:-}" > "$TMP/worker_send.json" <<'PY'
import json,sys
w=json.load(open("worker.json"))
w["skills"]=[{"type":"custom","skill_id":sys.argv[1],"version":"latest"}] if sys.argv[1] else []
print(json.dumps(w))
PY
  call "$TMP/worker.json" "$BASE/agents" "${H[@]}" -d @"$TMP/worker_send.json"
  save WORKER_ID "$(field "$TMP/worker.json" "['id']")"
}

step_agent() {   # the lead: roster + workflows point at the researcher
  [ -n "${AGENT_ID:-}" ] && { echo "agent: $AGENT_ID v${AGENT_VERSION:-?} (exists)"; return; }
  python3 - "$MODEL" "${SKILL_ID:-}" "$WORKER_ID" > "$TMP/agent_send.json" <<'PY'
import json,sys
a=json.load(open("agent.json")); a["model"]=sys.argv[1]
a["skills"]=[{"type":"custom","skill_id":sys.argv[2],"version":"latest"}] if sys.argv[2] else []
for part in ("subagents","workflows"):
    a["multiagent"][part]["predefined_agents"]=[sys.argv[3]]
print(json.dumps(a))
PY
  call "$TMP/agent.json" "$BASE/agents" "${H[@]}" -d @"$TMP/agent_send.json"
  save AGENT_ID "$(field "$TMP/agent.json" "['id']")"
  save AGENT_VERSION "$(field "$TMP/agent.json" "['version']")"
}

kickoff() { python3 - <<'PY'
import json
json.dump({"type":"user.define_outcome","description":open("first_prompt.txt").read(),
  "rubric":{"type":"text","content":open("outcome.md").read()},"max_iterations":3}, open("kickoff.json","w"), indent=2)
PY
}
BUDGET='{"type":"limit","max_list_cost":{"amount":"800","currency":"USD"}}'   # $8.00 hard cap per run (whole cents), covers subagents + workflow runs
MEM_RESOURCE='[{"type":"memory_store","memory_store_id":"%s","access":"read_write","instructions":"contacted/ = businesses already approached. Read it before picking leads; add contacted/<slug>.md for each new lead."},{"type":"memory_store","memory_store_id":"%s","access":"read_only","instructions":"opted-out/ = businesses that asked not to be contacted. Never contact anyone listed here."}]'
mem_resources() { printf "$MEM_RESOURCE" "$MEMSTORE_ID" "$OPTOUT_STORE_ID"; }

step_run() {
  local title=${1:-"run $(date +%F)"}; kickoff
  python3 - "$AGENT_ID" "$AGENT_VERSION" "$ENV_ID" "$title" "$(mem_resources)" "$BUDGET" > "$TMP/sess_send.json" <<'PY'
import json,sys
aid,ver,env,title,mem,budget=sys.argv[1:]
print(json.dumps({"agent":{"type":"agent","id":aid,"version":int(ver)},"environment_id":env,"title":title,
  "resources":json.loads(mem),"budget":json.loads(budget),"initial_events":[json.load(open("kickoff.json"))]}))
PY
  call "$TMP/sess.json" "$BASE/sessions" "${H[@]}" -d @"$TMP/sess_send.json"
  local sid; sid=$(field "$TMP/sess.json" "['id']")
  save SESSION_ID "$sid"; echo "$sid" >> sessions.log
  echo "  console: https://platform.claude.com/workspaces/default/sessions/$sid"
}

step_status() {
  call "$TMP/s.json" "$BASE/sessions/${1:-$SESSION_ID}" "${H[@]}"
  python3 - "$TMP/s.json" <<'PY'
import json,sys
d=json.JSONDecoder(strict=False).decode(open(sys.argv[1]).read())
print("status:", d["status"])
import re
ctl=lambda t: re.sub(r"[\x00-\x08\x0b-\x1f\x7f\u202a-\u202e\u2066-\u2069]", "", str(t))
for e in d.get("outcome_evaluations",[]): print("verdict:", ctl(e.get("result")), "-", ctl((e.get("explanation") or "")[:600]))
u=d.get("usage") or {}; print("usage:", {k:u[k] for k in u if k in ("input_tokens","output_tokens","list_cost","active_seconds")})
PY
}

step_outputs() {   # only after status is idle (file ids are re-finalized when the run settles)
  local sid=${1:-$SESSION_ID}; mkdir -p "out/$sid"
  call "$TMP/files.json" "$BASE/files?scope_id=$sid&limit=1000" "${H[@]}"
  # filenames come from the agent (and so, indirectly, from web pages): normalise and refuse anything escaping out/<sid>/
  python3 - "$TMP/files.json" "out/$sid" > "$TMP/files.tsv" <<'PY'
import json,os,re,sys
files,outdir=sys.argv[1:]; root=os.path.realpath(outdir)
for f in json.load(open(files))["data"]:
    fid=str(f["id"])
    if not re.fullmatch(r"[A-Za-z0-9_-]+", fid): continue
    name=str(f.get("filename") or fid)
    norm=os.path.normpath(name.lstrip("/")) if not re.search(r"[\x00-\x1f\x7f]", name) else ""
    dest=os.path.realpath(os.path.join(root, norm)) if norm and not norm.startswith("..") else ""
    if not dest.startswith(root+os.sep): norm="unsafe-name-"+fid
    print(fid, norm, sep="\t")
PY
  while IFS=$'\t' read -r fid name; do
    mkdir -p "out/$sid/$(dirname "$name")"
    curl -sS "$BASE/files/$fid/content" "${H[@]}" -o "out/$sid/$name" && printf '  %s\n' "$name"
  done < "$TMP/files.tsv"
  # demo pages must be plain HTML + CSS: fail loudly if anything script-like slipped in
  if [ -d "out/$sid/demos" ] && grep -rliE '<script|javascript:|[[:space:]]on[a-z]+[[:space:]]*=' "out/$sid/demos"; then
    echo "WARNING: script-like content found in the demo pages listed above - do not send them; check that run"; return 1
  fi
}

step_optout() {   # ./launch.sh optout "Business Name" "Area" ["email or phone"]
  local name=${1:?business name}; local area=${2:?area}; local contact=${3:-}
  local s; s=$(slug "$name" "$area")
  python3 - "$name" "$area" "$contact" "$s" > "$TMP/optout.json" <<'PY'
import json,sys,datetime
n,a,c,s=sys.argv[1:]
print(json.dumps({"path":f"/opted-out/{s}.md","content":f"# {n}\nArea: {a}\nContact: {c}\nOpted out: {datetime.date.today()}\nNever contact again.\n"}))
PY
  call "$TMP/opt.json" "$BASE/memory_stores/$OPTOUT_STORE_ID/memories" "${HMEM[@]}" -d @"$TMP/optout.json"
  echo "opted out: $name ($area)"
}

step_deploy() {
  [ -n "${DEPLOYMENT_ID:-}" ] && { echo "deployment: $DEPLOYMENT_ID (exists)"; return; }
  if grep -Eq '20[0-9]{2}-[0-9]{2}-[0-9]{2}' first_prompt.txt outcome.md; then echo "literal date in the kickoff text - fix before deploying"; exit 1; fi
  kickoff
  python3 - "$AGENT_ID" "$ENV_ID" "$(mem_resources)" "$BUDGET" > deployment.json <<'PY'
import json,sys
aid,env,mem,budget=sys.argv[1:]
print(json.dumps({"name":"Hyderabad website outreach - weekdays","agent":aid,"environment_id":env,
  "resources":json.loads(mem),"budget":json.loads(budget),"initial_events":[json.load(open("kickoff.json"))],
  "schedule":{"type":"cron","expression":"0 8 * * 1-5","timezone":"Asia/Kolkata"}}, indent=2))
PY
  call "$TMP/dep.json" "$BASE/deployments?beta=true" "${H[@]}" -d @deployment.json
  save DEPLOYMENT_ID "$(field "$TMP/dep.json" "['id']")"
  echo "upcoming runs: $(field "$TMP/dep.json" ".get('schedule',{}).get('upcoming_runs_at')")"
  echo "  console: https://platform.claude.com/workspaces/default/deployments/$DEPLOYMENT_ID"
}

step_deploy_run() { call "$TMP/run.json" -X POST "$BASE/deployments/$DEPLOYMENT_ID/run?beta=true" "${H[@]}" -d '{}'; cat "$TMP/run.json"; echo; }

case "${1:-all}" in
  all) step_model; step_env; step_memory; step_skill; step_worker; step_agent; step_run "first run" ;;
  model) step_model ;; env) step_env ;; memory) step_memory ;; skill) step_skill ;; worker) step_worker ;; agent) step_agent ;;
  run) step_run "${2:-}" ;; status) step_status "${2:-}" ;; outputs) step_outputs "${2:-}" ;;
  optout) shift; step_optout "$@" ;; deploy) step_deploy ;; deploy-run) step_deploy_run ;;
  *) echo "unknown step $1"; exit 1 ;;
esac
