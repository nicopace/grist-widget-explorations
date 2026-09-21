#!/usr/bin/env python3
"""Grist doc snapshot + bootstrap helper for the repo.

Keeps a Git-tracked, empty-but-structural Grist document plus a diffable SQL
snapshot, so we iterate on a file in version control instead of a live user doc.

Usage:
  python3 grist/sync.py pull  [--doc DOCID]   # server -> grist/*.grist + grist/snapshot.sql
  python3 grist/sync.py dump  [--file PATH]   # local .grist -> grist/snapshot.sql
  python3 grist/sync.py diff                  # git diff of snapshot.sql
  python3 grist/sync.py bootstrap [--doc ID] [--base URL] [--key KEY]
      # create missing B1/B2 records + junction rows for every submission

Auth: GRIST_API_KEY env var, else the key in ../opencode.json.
Base URL: GRIST_BASE_URL env var, default http://localhost:47478.
Byte-identity: after a pull, re-uploading the file via `POST .../{dstDocId}/replace`
or importing it on create reproduces the doc exactly.

The "flip" pattern (junction table as truth) means each submission needs a B1/B2
parent record and one junction row per community, but formulas cannot create rows.
`bootstrap` is the glue that fills those in for any submission missing them.
"""
import argparse
import json
import os
import pathlib
import sqlite3
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
FORK_DOC = "jrP3kqTf6nSBtDYo2nUkcF"  # MEAL3-flip-test (the flipped reference fork)
DEFAULT_GRISt = ROOT / "meal.grist"
SNAPSHOT = ROOT / "snapshot.sql"


def load_config():
    base = os.environ.get("GRIST_BASE_URL")
    key = os.environ.get("GRIST_API_KEY")
    if not key:
        cfg = ROOT.parent / "opencode.json"
        if cfg.exists():
            env = json.loads(cfg.read_text())["mcp"]["grist"].get("environment", {})
            key = key or env.get("GRIST_API_KEY")
            base = base or env.get("GRIST_BASE_URL")
    return (base or "http://localhost:47478"), key


def aslist(v):
    if v is None:
        return []
    if isinstance(v, list):
        return [int(x) for x in (v[1:] if v and v[0] == "L" else v)]
    return [int(v)]


def _request(method, url, key, payload=None):
    data = None
    headers = {"Authorization": f"Bearer {key}"}
    if payload is not None:
        data = json.dumps(payload).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def api_get(base, key, doc, path):
    return _request("GET", f"{base}/api/docs/{doc}{path}", key)


def api_apply(base, key, doc, actions):
    return _request("POST", f"{base}/api/docs/{doc}/apply", key, actions)


def bootstrap(doc, base, key):
    """Ensure every submission has a B1 record, B2 record, and junction rows."""
    subs = api_get(base, key, doc, "/tables/Submission/records")["records"]
    b1s = api_get(base, key, doc, "/tables/B1_Work_on_the_ground/records")["records"]
    b2s = api_get(base, key, doc, "/tables/B2_Threat/records")["records"]
    b1j = api_get(base, key, doc, "/tables/B1_Community_Check/records")["records"]
    b2j = api_get(base, key, doc, "/tables/B2_Community_Check/records")["records"]

    b1_by_sub = {r["fields"].get("Submission"): r["id"] for r in b1s}
    b2_by_sub = {r["fields"].get("Submission_B2"): r["id"] for r in b2s}
    b1j_keys = {(r["fields"].get("B1"), r["fields"].get("Community")) for r in b1j}
    b2j_keys = {(r["fields"].get("B2"), r["fields"].get("Community")) for r in b2j}

    for s in subs:
        sid = s["id"]
        comms = aslist(s["fields"].get("Communities"))
        name = s["fields"].get("Submission_name") or f"#{sid}"
        created = []

        if sid not in b1_by_sub:
            b1id = api_apply(base, key, doc, [["AddRecord", "B1_Work_on_the_ground", None, {"Submission": sid}]])["retValues"][0]
            b1_by_sub[sid] = b1id
            api_apply(base, key, doc, [["UpdateRecord", "Submission", sid, {"B1": b1id}]])
            created.append(f"B1 record #{b1id}")
        b1id = b1_by_sub[sid]

        if sid not in b2_by_sub:
            b2id = api_apply(base, key, doc, [["AddRecord", "B2_Threat", None, {"Submission_B2": sid}]])["retValues"][0]
            b2_by_sub[sid] = b2id
            api_apply(base, key, doc, [["UpdateRecord", "Submission", sid, {"B2": b2id}]])
            created.append(f"B2 record #{b2id}")
        b2id = b2_by_sub[sid]

        missing_b1 = [c for c in comms if (b1id, c) not in b1j_keys]
        if missing_b1:
            api_apply(base, key, doc, [
                ["AddRecord", "B1_Community_Check", None, {"B1": b1id, "Community": c, "Submission": sid}]
                for c in missing_b1])
            b1j_keys |= {(b1id, c) for c in missing_b1}
            created.append(f"{len(missing_b1)} B1 junction rows")

        missing_b2 = [c for c in comms if (b2id, c) not in b2j_keys]
        if missing_b2:
            api_apply(base, key, doc, [
                ["AddRecord", "B2_Community_Check", None, {"B2": b2id, "Community": c, "Submission": sid}]
                for c in missing_b2])
            b2j_keys |= {(b2id, c) for c in missing_b2}
            created.append(f"{len(missing_b2)} B2 junction rows")

        print(f"  {name} (id {sid}): " + (", ".join(created) if created else "already complete"))


def pull(doc_id, out_path):
    base, key = load_config()
    if not key:
        sys.exit("No GRIST_API_KEY found (env or ../opencode.json)")
    url = f"{base}/api/docs/{doc_id}/download"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req) as resp:
        data = resp.read()
    if not data.startswith(b"SQLite format 3"):
        sys.exit("Download did not return a SQLite .grist file")
    out_path.write_bytes(data)
    print(f"pulled {doc_id} -> {out_path} ({len(data)} bytes)")


def dump(grist_path, out_path):
    con = sqlite3.connect(f"file:{grist_path}?mode=ro", uri=True)
    kind = {v: k for k, v in con.execute("SELECT name, type FROM sqlite_master").fetchall()}
    tables = [r[0] for r in con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE '_grist%' AND name NOT LIKE '_gristsys%' ORDER BY name").fetchall()]
    lines = ["-- Grist document snapshot (diffable). Regenerate: python3 grist/sync.py dump",
             f"-- source: {grist_path.name}",
             "-- Grist internal helper columns (gristHelper_*, manualSort) are omitted.", ""]
    for t in tables:
        cols = [r[1] for r in con.execute(f'PRAGMA table_info("{t}")').fetchall()
                if not r[1].startswith("gristHelper_") and r[1] != "manualSort"]
        if not cols:
            continue
        qcols = ", ".join(f'"{c}"' for c in cols)
        lines.append(f"-- {t}")
        lines.append(f"CREATE TABLE {t} ({', '.join(cols)});")
        for row in con.execute(f'SELECT {qcols} FROM "{t}"'):
            vals = []
            for v in row:
                if v is None:
                    vals.append("NULL")
                elif isinstance(v, (int, float)):
                    vals.append(str(v))
                elif isinstance(v, bytes):
                    vals.append("X'%s'" % v.hex())
                else:
                    vals.append("'" + str(v).replace("'", "''") + "'")
            lines.append(f"INSERT INTO {t} VALUES ({', '.join(vals)});")
        lines.append("")
    out_path.write_text("\n".join(lines) + "\n")
    print(f"dumped {len(tables)} tables -> {out_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["pull", "dump", "diff", "bootstrap"])
    ap.add_argument("--doc", default=FORK_DOC)
    ap.add_argument("--file", default=str(DEFAULT_GRISt))
    ap.add_argument("--base", default=None)
    ap.add_argument("--key", default=None)
    a = ap.parse_args()
    if a.action == "pull":
        pull(a.doc, DEFAULT_GRISt)
        dump(DEFAULT_GRISt, SNAPSHOT)
    elif a.action == "dump":
        dump(pathlib.Path(a.file), SNAPSHOT)
    elif a.action == "bootstrap":
        base, key = load_config()
        base = a.base or base
        key = a.key or key
        if not key:
            sys.exit("No GRIST_API_KEY found (env, --key, or ../opencode.json)")
        bootstrap(a.doc, base, key)
    else:
        subprocess.run(["git", "-C", str(ROOT.parent), "diff", "--", str(SNAPSHOT.relative_to(ROOT.parent))])


if __name__ == "__main__":
    main()
