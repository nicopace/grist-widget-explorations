# Grist FPP — project notes for agents

## Strategy: native junction table as the editable truth (a.k.a. "the flip")

Use this pattern for many-to-many matrices (e.g. communities × work categories) when
the goal is maximum use of built-in Grist features and minimum external code.

### The pattern

1. Create a junction table with one row per (parent × option), e.g.
   `B1_Community_Check`: refs to the parent (`B1`), the option (`Community`), a
   denormalized scope ref (`Submission`), plus one editable `Bool` column per
   category.
2. Convert the original many-to-many columns (e.g. the 13 `RefList:Community`
   columns on `B1_Work_on_the_ground`) into **formula columns** that collect from
   the junction:
   `[r.Community for r in B1_Community_Check.lookupRecords(B1=rec.id) if r.<Bool>]`
   These become read-only and drift-free by construction.
3. Editing happens on the junction checkboxes (native grid widget, or a custom
   matrix widget that writes the junction `Bool`s). No sync step, no buttons.
4. Add a **uniqueness guard** so multi-period entry stays safe:
   - `Key` (Text, formula): `str($B1) + ':' + str($Community)`
   - `Duplicate` (Bool, formula): `len(B1_Community_Check.lookupRecords(Key=$Key)) > 1`
   Both existing rows of a duplicated pair flag `True`.

### Why (and what was ruled out)

- **Trigger formulas cannot write other tables** — they only compute their own
  cell. So junction→RefList sync via a column trigger is impossible.
- **Grist Automations** only support "send email" / "create webhook" actions, no
  in-doc record updates — a webhook would need an external service to call back.
- **Formula columns as collectors** are the only all-native path, and they work:
  a junction checkbox change recalculates the parent RefList with zero glue.

### Constraints to remember

- Junction **rows** cannot be created by formulas. A widget's find-or-create on
  toggle (or manual row-add) supplies the missing rows.
- Scope is the current option universe of the period (e.g. `Submission.Communities`)
  plus any row already present. Changes to the universe need a bootstrap pass.
- The original parent columns become read-only; all editing must move to the
  junction grid/widget.
- Writing RefLists through `docApi.applyUserActions` requires canonical
  `["L", ...ids]` encoding and `["L"]` to clear — plain arrays/`null` corrupt the
  cell with a marshalled `KeyError`. Prefer writing plain `Bool` data columns
  instead. (The corruption is specific to the action API; formula `[]` is fine.)

### Where this was applied

- Live doc `MEAL3` (`aP5RhFHGj9Bm1VX7hJA9ow`): junction table + native grid +
  manual Push/Pull sync widget (`b1-sync.html`) + RefList-writing matrix
  (`b1-matrix.html`). Source of truth still the RefLists.
- Fork `MEAL3-flip-test` (`jrP3kqTf6nSBtDYo2nUkcF`): the flip applied — 13 B1
  RefList columns are formulas, junction is truth, guard columns `Key`/`Duplicate`
  added, matrix widget `b1-matrix-junction.html` writes junction Bools.

### Hosting

Widgets are served locally with `python3 -m http.server 8123 --directory /Users/nico/github/grist-fpp`
and wired into `_grist_Views_section.options` via REST `PATCH` (the MCP page tools
cannot write widget URLs). Bump `?v=N` on the URL to defeat iframe caching.

## Standard workflow: repo-local Grist server + git-backed doc

Use this for all Grist work from now on. It avoids depending on Grist Desktop and
never mutates a live user document.

```bash
./grist/run.sh start     # local gristlabs/grist in Docker, data in .grist-server/ (gitignored)
./grist/run.sh import    # upload grist/meal.grist into the Home workspace; prints docId + URL
#   edit in the browser at http://localhost:8484/o/docs/<docId>
./grist/run.sh export    # server doc -> grist/meal.grist + refresh grist/snapshot.sql
git diff grist/snapshot.sql
```

- `grist/meal.grist` is the canonical, git-tracked document; `grist/snapshot.sql`
  is the human-readable diff layer (regenerate with `python3 grist/sync.py dump`).
- API base is `http://localhost:8484/api`, key `gristfpp-local-dev-key`
  (written into the local home DB by `run.sh start`).
- Only `export` touches tracked files, so browser edits stay untracked until reviewed.

### Adding a new submission/period (in-document, no external step)

The flip means junction rows (and their B1/B2 parent records) cannot be created by
formulas. So a brand-new submission shows an empty checkbox grid until its rows
exist. This is handled by the **auto-bootstrap widget** (`pending-rows.html`), a
small strip on the left of both the `B1. Work on the ground` and `B2. Threat`
pages. It runs automatically on page load — no button, no manual action — and adds
the missing B1/B2 record and one junction row per community for every submission,
via the plugin API. Idempotent; existing rows are untouched. It is scoped per page
through the widget URL (`?scope=b1` on B1, `?scope=b2` on B2).

- After adding a new submission and setting its communities, just open the B1 (or
  B2) page — the widget shows `+N` briefly while it creates the rows, then `✓`.
- There is also a scripted equivalent (`./grist/run.sh bootstrap`, i.e.
  `python3 grist/sync.py bootstrap`) kept as a fallback/verification tool — not
  part of the normal workflow.

