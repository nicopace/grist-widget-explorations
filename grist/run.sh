#!/usr/bin/env bash
# Run a local Grist server (gristlabs/grist in Docker) backed by the repo file
# grist/meal.grist. No Grist Desktop required; open the UI in a browser.
#
#   ./grist/run.sh start          # start server (default port 8484), create API key if needed
#   ./grist/run.sh stop           # stop server
#   ./grist/run.sh restart        # stop + start
#   ./grist/run.sh status         # running?
#   ./grist/run.sh logs           # follow server logs
#   ./grist/run.sh shell          # shell into the container
#   ./grist/run.sh import         # upload grist/meal.grist -> server, prints docId (saved to .grist-server/DOCID)
#   ./grist/run.sh open           # print the browser URL for the imported doc
#   ./grist/run.sh export [docId] # download server doc -> grist/meal.grist + refresh snapshot.sql
#
# Server data lives in .grist-server/ (gitignored). Use `import` once, edit in the
# browser at http://localhost:8484, then `export` to write changes back into
# grist/meal.grist for committing.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
IMAGE="${GRIST_IMAGE:-gristlabs/grist:latest}"
NAME="${GRIST_CONTAINER:-grist-fpp}"
PORT="${GRIST_PORT:-8484}"
DATA_DIR="${GRIST_DATA_DIR:-$REPO/.grist-server}"
DOC_FILE="$HERE/meal.grist"
DOCID_FILE="$DATA_DIR/DOCID"
API="http://localhost:$PORT/api"
API_KEY="${GRIST_API_KEY:-gristfpp-local-dev-key}"
SESSION_SECRET="${GRIST_SESSION_SECRET:-gristfpp-local-session-secret}"
DEFAULT_EMAIL="${GRIST_DEFAULT_EMAIL:-dev@localhost}"
ROOT="http://localhost:$PORT"

die() { echo "error: $*" >&2; exit 1; }
ensure_docker() { docker info >/dev/null 2>&1 || die "Docker daemon not running. Start Docker and retry."; }
running() { docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null | grep -q true; }

# Give the local owner a known API key directly in the home DB, before the server
# starts (the server caches users at boot, so the write must precede startup).
# This dev server is single-user and only bound to localhost, so it's fine.
ensure_api_key() {
  # home.sqlite3 is on the host bind mount, so edit it directly (no docker cp).
  [ -f "$DATA_DIR/home.sqlite3" ] || return 0
  python3 - "$DATA_DIR/home.sqlite3" "$API_KEY" "$DEFAULT_EMAIL" <<'PY'
import sqlite3, sys
db, key, email = sys.argv[1], sys.argv[2], sys.argv[3]
con = sqlite3.connect(db)
# Target the configured default login, creating the user row if the bootstrap
# hasn't produced it yet. This is what the server authenticates as.
row = con.execute("SELECT user_id FROM logins WHERE email=?", (email,)).fetchone()
if row is None:
    cur = con.execute("INSERT INTO users (name, type) VALUES (?, 'login')", ("You",))
    uid = cur.lastrowid
    con.execute("INSERT INTO logins (email, user_id, display_email) VALUES (?,?,?)",
                (email, uid, email))
else:
    uid = row[0]
con.execute("UPDATE users SET api_key=? WHERE id=?", (key, uid))
con.commit()
print(f"api key set for {email} (user id {uid})")
PY
}

# Start the server. Grist caches users at boot, so the API key can only take
# effect on a following start: on first run we start, set the key on the host
# bind-mounted home DB, then restart. Everything after that is a plain start.
cmd_start() {
  ensure_docker
  mkdir -p "$DATA_DIR"
  if running; then echo "already running: $NAME on :$PORT"; return 0; fi
  local first_run=false
  [ -f "$DATA_DIR/home.sqlite3" ] || first_run=true

  _launch
  if $first_run; then
    echo "first run: creating home database…"
    _wait_http
    ensure_api_key
    echo "restarting to apply API key…"
    _launch   # restart so the server picks up the new key
  fi
  _wait_http
  echo "started $NAME on $ROOT  (data: $DATA_DIR)"
}

_launch() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  # Run as the host user so bind-mounted files under $DATA_DIR stay writable by
  # the server (otherwise root-owned files cause SQLITE_READONLY).
  docker run -d --name "$NAME" \
    --user "$(id -u):$(id -g)" \
    -p "$PORT:8484" \
    -v "$DATA_DIR:/persist" \
    -e GRIST_SESSION_SECRET="$SESSION_SECRET" \
    -e GRIST_DEFAULT_EMAIL="$DEFAULT_EMAIL" \
    -e GRIST_IN_SERVICE=true \
    -e GRIST_ANON_PLAYGROUND=true \
    -e GRIST_INST_DIR=/persist \
    "$IMAGE" >/dev/null
}

_wait_http() {
  printf "waiting for server"
  for _ in $(seq 1 90); do
    if curl -sf -o /dev/null "$ROOT/"; then echo " ok"; return 0; fi
    printf "."; sleep 1
  done
  echo; die "server did not come up; see: $0 logs"
}

cmd_stop()  { ensure_docker; docker rm -f "$NAME" >/dev/null 2>&1 && echo "stopped $NAME" || echo "not running"; }
cmd_logs()  { ensure_docker; docker logs -f "$NAME"; }
cmd_shell() { ensure_docker; docker exec -it "$NAME" bash; }
cmd_status(){ ensure_docker; running && echo "running on $ROOT" || echo "not running"; }

# Resolve the workspace to put the imported doc in (the local owner's Home).
# Requires the API key set during `start`.
resolve_workspace() {
  local org ws
  org="$(curl -sf -H "Authorization: Bearer $API_KEY" "$API/orgs" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")" || return 1
  [ -n "$org" ] || return 1
  ws="$(curl -sf -H "Authorization: Bearer $API_KEY" "$API/orgs/$org/workspaces" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")" || return 1
  printf '%s' "$ws"
}

cmd_import() {
  ensure_docker
  [ -f "$DOC_FILE" ] || die "missing $DOC_FILE"
  local ws; ws="$(resolve_workspace)" || true
  [ -n "$ws" ] || die "could not resolve a workspace (is the API key set? try: $0 restart)"
  # workspaceId makes Grist save the doc into Home, so it shows up in the UI.
  # Without it, the import creates an unsaved doc only reachable by URL.
  local out; out="$(curl -sf -X POST -H "Authorization: Bearer $API_KEY" \
      -F "upload=@$DOC_FILE" -F "workspaceId=$ws" -F "documentName=${GRIST_DOC_NAME:-meal}" \
      "$API/docs")" || die "import failed (is the API key set? try: $0 restart)"
  local doc; doc="$(printf '%s' "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d if isinstance(d,str) else d.get('id',''))")"
  mkdir -p "$DATA_DIR"; printf '%s' "$doc" > "$DOCID_FILE"
  echo "imported -> docId: $doc (workspace $ws)"
  echo "open in browser: $ROOT/o/docs/$doc"
}

cmd_open() {
  local doc; doc="$(cat "$DOCID_FILE" 2>/dev/null || true)"
  [ -n "$doc" ] || die "no imported doc yet; run: $0 import"
  echo "$ROOT/o/docs/$doc"
}

cmd_export() {
  ensure_docker
  local doc="${1:-}"; [ -n "$doc" ] || doc="$(cat "$DOCID_FILE" 2>/dev/null || true)"
  [ -n "$doc" ] || die "usage: $0 export <docId>   (or run: $0 import first)"
  curl -sf -H "Authorization: Bearer $API_KEY" "$API/docs/$doc/download" -o "$DOC_FILE" \
    || die "export failed (docId=$doc)"
  echo "wrote $DOC_FILE ($(wc -c <"$DOC_FILE") bytes)"
  python3 "$HERE/sync.py" dump --file "$DOC_FILE" >/dev/null && echo "refreshed grist/snapshot.sql"
}

case "${1:-status}" in
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  restart) cmd_stop; cmd_start ;;
  logs)    cmd_logs ;;
  shell)   cmd_shell ;;
  status)  cmd_status ;;
  import)  cmd_import ;;
  open)    cmd_open ;;
  export)  shift; cmd_export "$@" ;;
  *) die "unknown command: $1 (start|stop|restart|status|logs|shell|import|open|export)" ;;
esac
