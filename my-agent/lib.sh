# Sourced by launch.sh / deploy.sh / evals/run-evals.sh. Loads .env + IDS.env, defines api().
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_shell_key=${ANTHROPIC_API_KEY:-}; _shell_repo=${REPO_TOKEN:-}
set -a
[ -f "$DIR/.env" ] && . "$DIR/.env"
[ -f "$DIR/IDS.env" ] && . "$DIR/IDS.env"
set +a
# an exported key in the shell wins over an empty placeholder in .env
export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-$_shell_key} REPO_TOKEN=${REPO_TOKEN:-$_shell_repo}
: "${ANTHROPIC_API_KEY:?not set: paste it into $DIR/.env or export it}"

BASE=https://api.anthropic.com/v1
H=(-H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01"
   -H "anthropic-beta: managed-agents-2026-04-01" -H "content-type: application/json")
RESP=$(mktemp)
CONSOLE=https://platform.claude.com/workspaces/${WORKSPACE:-default}

# api METHOD PATH [BODY]: response lands in $RESP; non-2xx prints the body and fails
api() {
  local args=(-sS -X "$1" "$BASE$2" "${H[@]}" -o "$RESP" -w '%{http_code}')
  [ -n "${3:-}" ] && args+=(--data-binary "$3")
  local code; code=$(curl "${args[@]}")
  if [[ $code != 2* ]]; then echo "HTTP $code on $1 $2" >&2; cat "$RESP" >&2; echo >&2; return 1; fi
}
get() { python3 "$DIR/cma.py" get "$RESP" "$1"; }
save_id() { echo "$1=$2" >> "$DIR/IDS.env"; export "$1=$2"; }
