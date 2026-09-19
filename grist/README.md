# Git-backed Grist document

An empty-but-structural copy of the flipped test document, kept in version control
so we can iterate on a file instead of mutating a live user's doc.

| File | What it is |
|---|---|
| `meal3-flip.grist` | The canonical Grist document (SQLite, byte-identical round-trip). Import/upload this to get the doc back. Its binary diff is unusable, which is why the snapshot below exists. |
| `snapshot.sql` | Human-readable, diffable dump of all user tables (Grist helper columns omitted). This is what you review in `git diff`. |
| `sync.py` | Pull/dump/diff helper. |

## Workflow

```bash
# pull the reference doc + refresh the diffable snapshot
python3 grist/sync.py pull            # fork jrP3kqTf6nSBtDYo2nUkcF by default
python3 grist/sync.py pull --doc <ID> # any other doc

# after editing a local .grist file
python3 grist/sync.py dump --file path/to/doc.grist

# review changes
python3 grist/sync.py diff
```

Auth comes from `GRIST_API_KEY` / `GRIST_BASE_URL` env vars, falling back to
`../opencode.json`. Default base URL is `http://localhost:47478`.

## Round-trip

`.grist` files are self-contained and portable:

- **Read locally**: `sqlite3 grist/meal3-flip.grist ".tables"`
- **Restore into Grist**: `POST /api/docs/{dstDocId}/replace` with the file, or
  import it when creating a document. A pull→push cycle reproduces the doc exactly.

## Convention

Keep this doc **empty of real user data**. It exists to hold structure — tables,
columns, formulas, the junction layout, pages — so experiments stay reviewable and
the user's working docs are never the test bed.
