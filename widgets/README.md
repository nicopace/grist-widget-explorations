# Grist widgets

Custom widgets for the MEAL document and a few standalone experiments. Each is a
single self-contained HTML file served over plain HTTP and wired into a Grist page
as a **Custom** widget (full access) via a `_grist_Views_section.options`
`customView` URL.

## Hosting

Serve the repo root with any static server, e.g.:

```bash
python3 -m http.server 8123 --directory /Users/nico/github/grist-fpp
```

Then the URL for a widget is `http://localhost:8123/<path>.html`. After editing a
widget, bump `?v=N` on the URL (or hard-refresh) — Grist iframes cache aggressively.

> **Plugin API URL note.** `widgets/b1/` and `examples/lastseen.html` load the API
> from `https://docs.getgrist.com/grist-plugin-api.js` (portable, any Grist). The
> `widgets/aurora/` and `examples/age-widget.html` load it from
> `http://localhost:47478/grist-plugin-api.js` (hard-coded to Grist Desktop) and
> will only work against that instance.

## `widgets/b1/` — MEAL "Work on the ground" / "Threat" matrix

These implement the **junction-as-truth** pattern for the many-to-many
`community × category` matrices on the B1/B2 pages. The canonical schema is:

- A junction table (`B1_Community_Check`, `B2_Community_Check`) with one row per
  (B1/B2 record × community) and one editable `Bool` column per category.
- The original `RefList:Community` columns on `B1_Work_on_the_ground` /
  `B2_Threat` are **formula columns** that collect from the junction:
  `[r.Community for r in B1_Community_Check.lookupRecords(B1=rec.id) if r.<Bool>]`.

The junction is the editable truth; the RefLists are read-only and drift-free.

### `pending-rows.html` — auto-bootstrap (active)

Runs automatically on page load — no button. Ensures every submission has its B1/B2
record and one junction row per community, creating whatever is missing.

- **Use:** place as a Custom widget (full access) on the `B1. Work on the ground`
  and `B2. Threat` pages. Scope it per page via the URL: `?scope=b1` on B1,
  `?scope=b2` on B2 (default `all` does both). It shows `…` while working, `+N`
  briefly after creating rows, then `✓`; `!N` on error.
- **Caveats:**
  - Runs on every page load (a fetch + analyze). Negligible now, but on a large
    doc it's a small constant cost per navigation.
  - It only *adds* missing rows; it never deletes stale ones. Removing a community
    from a submission leaves its junction row behind (harmless, but the row stays).
  - Requires `requiredAccess: full`.
  - `?v=N` must be bumped after edits or the browser serves the cached iframe.

### `b1-matrix.html` — matrix writing RefLists directly (superseded)

A checkbox matrix (communities × categories) that edits the 13 `RefList:Community`
columns on `B1_Work_on_the_ground` in place. Predates the junction flip.

- **Caveats:**
  - Writing a `RefList` through `docApi.applyUserActions` requires the canonical
    `["L", ...ids]` encoding (and `["L"]` to clear). Plain arrays / `null` corrupt
    the cell with a marshalled `KeyError`. This was the original bug, later fixed.
  - **Superseded** by the junction approach + native grid + `pending-rows.html`.

### `b1-matrix-junction.html` — matrix writing junction Bools (superseded)

Same matrix UX, but toggles write the junction `Bool` cells instead of the
RefLists, and find-or-create the junction row on toggle. The B1 formula columns
then recalculate automatically.

- **Caveats:**
  - Requires the junction table and the B1/B2 formula columns to already exist.
  - **Superseded** by the native checkbox grid (`B1 participant checkboxes` /
    `B2 threat participant checkboxes`) plus `pending-rows.html`, which remove the
    need for any custom editor widget.

### `b1-sync.html` — manual push/pull sync (superseded)

A button strip to sync between the junction and the RefLists by hand: "↓ Pull from
RefLists" rebuilds junction rows (deleting out-of-scope ones); "↑ Push to RefLists"
writes the junction checkboxes into the RefLists (with the `["L", ...]` encoding).

- **Caveats:**
  - Manual — drift is possible between clicks. **Superseded** by the flip, where
    the RefLists are formulas and no sync is needed at all.
  - Only useful today as a one-off repair/verification tool.

### `b1-dragboard.html` — drag-and-drop board (abandoned)

An early prototype that assigns communities to topics by dragging chips into
buckets. It targets an old schema (`Communities` / `Topics` / `B1_Answers`) that no
longer exists in the document.

- **Caveats:** does not match the current schema; kept only as a reference for the
  `V()`/`normId()`/`asList()` helpers and `L`-encoding handling.

## `widgets/aurora/` — Aurora mission dashboard (separate prototype)

A distinct, unrelated prototype for a "mission tracking" dashboard. All widgets
read a `Missions`-style table and hard-code the Desktop plugin API
(`localhost:47478`), so they only run against Grist Desktop.

| Widget | What it shows |
|---|---|
| `aurora-deck.html` | Flight deck overview of missions |
| `aurora-status.html` | Status board: outcome + duration + cost of the selected mission |
| `aurora-timeline.html` | Mission timeline |
| `aurora-impact.html` | Impact podium |
| `aurora-report.html` | Annual review, incl. a spend-by-outcome donut |
| `aurora-anomaly.html` | Anomaly scope for a linked mission |

- **Caveats:** not part of the MEAL work; not maintained; Desktop-only plugin API.

## `widgets/examples/` — standalone demos

### `age-widget.html` — "Age over 40" indicator

Minimal read-only demo: colors a box green/red based on whether the selected
person's `Age > 40`.

- **Use:** bind to a People-like table, map `Name` and `Age`, set `read table`.
- **Caveats:** `requiredAccess: read table`; hard-codes the Desktop plugin API.

### `lastseen.html` — "Last seen" timestamp

Tracks when each user last had the document open, by creating a temporary row in a
helper `UserPing` table whose `User_Email` is a trigger formula `user.Email`, then
updating a `Last Seen` DateTime on the matching user row.

- **Use:** needs a `UserPing` table with a `User_Email` column whose trigger
  formula is `user.Email`; bind the widget to your **Users** table and map
  `User Email Field` → email column, `Last Seen Field` → timestamp column.
- **Caveats:**
  - Writes trigger `onRecords` re-fires, so every write is gated by a `hasSettled`
    guard set **before** writing (loop-safe).
  - Skips updates newer than 5 minutes; retries with exponential backoff up to 10
    minutes on transient failures; permanent config errors settle terminally.
  - Requires `requiredAccess: full` and a writable `UserPing` table.
