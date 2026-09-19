# Git-backed Grist document

A structural copy of the flipped test document, kept in version control so we can
iterate on a file instead of mutating a live user's doc.

| File | What it is |
|---|---|
| `meal.grist` | The canonical Grist document (SQLite). Edit via the local server, then `export` it back here. Its binary diff is unusable, which is why the snapshot exists. |
| `snapshot.sql` | Human-readable, diffable dump of all user tables (Grist helper columns omitted). This is what you review in `git diff`. |
| `run.sh` | Runs a local Grist server (Docker) backed by `meal.grist`. No Grist Desktop needed. |
| `sync.py` | Dump/diff helper, and `pull` for pulling from an *external* runnable Grist. |

## Run Grist from the repo (recommended)

No Grist Desktop involved. `run.sh` starts the official `gristlabs/grist` image with
its data directory inside the repo (`.grist-server/`, gitignored) and imports
`meal.grist` into it:

```bash
./grist/run.sh start     # start server on http://localhost:8484
./grist/run.sh import    # upload grist/meal.grist, prints docId + browser URL
#   -> edit in the browser at the printed http://localhost:8484/o/docs/<docId>
./grist/run.sh export    # server doc -> grist/meal.grist + refresh snapshot.sql
git diff grist/snapshot.sql
```

Other commands: `stop`, `restart`, `status`, `logs`, `shell`, `open`.

The server is single-user and bound to localhost; `run.sh` writes a fixed API key
into the local home DB so the REST API works without browser logins. Override with
`GRIST_API_KEY`, `GRIST_PORT`, `GRIST_IMAGE`, `GRIST_DATA_DIR` if needed.

Only the `export` step touches tracked files, so the browser session can be as
messy as you like — nothing is committed until you review the snapshot diff.

## Pull from another Grist (Desktop or remote)

```bash
python3 grist/sync.py pull            # from jrP3kqTf6nSBtDYo2nUkcF on localhost:47478
python3 grist/sync.py pull --doc <ID> # any other doc
python3 grist/sync.py dump --file path/to/doc.grist
python3 grist/sync.py diff
```

Auth comes from `GRIST_API_KEY` / `GRIST_BASE_URL` env vars, falling back to
`../opencode.json`. Default base URL is `http://localhost:47478`.

## Round-trip

`.grist` files are self-contained and portable:

- **Read locally**: `sqlite3 grist/meal.grist ".tables"`
- **Restore into Grist**: `POST /api/docs` with the file as an upload (what `import`
  does), or `POST /api/docs/{docId}/replace`.

Note: importing rewrites Grist's own "Link to Submission" formula URLs in the
snapshot (they embed the doc/host), so expect a 2-line cosmetic diff after a move
between environments. That is not a data change.

## Convention

Keep this doc **empty of real user data**. It exists to hold structure — tables,
columns, formulas, the junction layout, pages — so experiments stay reviewable and
the user's working docs are never the test bed.
