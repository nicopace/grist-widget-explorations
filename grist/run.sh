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
ROOT="http://localhost:$PORT"

die() { echo "error: $*" >&2; exit 1; }
ensure_docker() { docker info >/dev/null 2>&1 || die "Docker daemon not running. Start Docker and retry."; }
running() { docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null | grep -q true; }

# Give the default local user a known API key directly in the home DB.
# This dev server is single-user and only bound to localhost, so it's fine.
ensure_api_key() {
  local tmp; tmp="$(mktemp -d)"
  docker cp "$NAME:/persist/home.sqlite3" "$tmp/home.sqlite3" >/dev/null 2>&1 || { rm -rf "$tmp"; return 0; }
  python3 - "$tmp/home.sqlite3" "$API_KEY" <<'PY'
import sqlite3, sys
db, key = sys.argv[1], sys.argv[2]
con = sqlite3.connect(db)
# The local owner is the non-system login user (not anon/preview/everyone/support).
row = con.execute("""SELECT u.id FROM users u JOIN logins l ON l.user_id=u.id
                     WHERE u.type='login' AND l.email NOT IN
                     ('anon@getgrist.com','thumbnail@getgrist.com','everyone@getgrist.com','support@getgrist.com')
                     ORDER BY u.id LIMIT 1""").fetchone()
if row:
    con.execute("UPDATE users SET api_key=? WHERE id=?", (key, row[0]))
    con.commit()
    print("api key set for user id", row[0])
else:
    print("no local user found (will retry after first browser login)")
PY
  docker cp "$tmp/home.sqlite3" "$NAME:/persist/home.sqlite3" >/dev/null 2>&1 || true
  rm -rf "$tmp"
}

cmd_start() {
  ensure_docker
  mkdir -p "$DATA_DIR"
  if running; then echo "already running: $NAME on :$PORT"; return 0; fi
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker run -d --name "$NAME" \
    -p "$PORT:8484" \
    -v "$DATA_DIR:/persist" \
    -e GRIST_SESSION_SECRET="$SESSION_SECRET" \
    -e GRIST_DEFAULT_EMAIL="dev@localhost" \
    -e GRIST_IN_SERVICE=true \
    -e GRIST_ANON_PLAYGROUND=true \
    -e GRIST_INST_DIR=/persist \
    "$IMAGE" >/dev/null
  echo "started $NAME on $ROOT  (data: $DATA_DIR)"
  printf "waiting for server"
  for _ in $(seq 1 60); do
    if curl -sf -o /dev/null "$ROOT/"; then echo " ok"; break; fi
    printf "."; sleep 1
  done
  ensure_api_key
}

cmd_stop()  { ensure_docker; docker rm -f "$NAME" >/dev/null 2>&1 && echo "stopped $NAME" || echo "not running"; }
cmd_logs()  { ensure_docker; docker logs -f "$NAME"; }
cmd_shell() { ensure_docker; docker exec -it "$NAME" bash; }
cmd_status(){ ensure_docker; running && echo "running on $ROOT" || echo "not running"; }

cmd_import() {
  ensure_docker
  [ -f "$DOC_FILE" ] || die "missing $DOC_FILE"
  local out; out="$(curl -sf -X POST -H "Authorization: Bearer $API_KEY" \
      -F "upload=@$DOC_FILE" "$API/docs")" || die "import failed (is the API key set? try: $0 restart)"
  local doc; doc="$(printf '%s' "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d if isinstance(d,str) else d.get('id',''))")"
  mkdir -p "$DATA_DIR"; printf '%s' "$doc" > "$DOCID_FILE"
  echo "imported -> docId: $doc"
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
