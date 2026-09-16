#!/bin/sh
# Preview by default; --apply creates/updates declared labels and never deletes any.
set -eu
cd "$(dirname "$0")/.."
python3 - "$@" <<'PYTHON'
import argparse
import json
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description="Preview or apply .github/labels.json")
parser.add_argument("repository", help="Explicit OWNER/REPO target")
parser.add_argument("--apply", action="store_true")
args = parser.parse_args()
if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repository):
    parser.error("repository must be OWNER/REPO")
labels = json.loads(Path(".github/labels.json").read_text())
if not isinstance(labels, list):
    parser.error("labels.json must contain an array")
seen = set()
for label in labels:
    if (not isinstance(label, dict) or set(label) != {"name", "color", "description"}
            or not isinstance(label["name"], str) or not label["name"].strip()
            or len(label["name"]) > 50
            or not isinstance(label["description"], str) or len(label["description"]) > 100
            or not isinstance(label["color"], str)
            or not re.fullmatch(r"[0-9a-fA-F]{6}", label["color"])):
        parser.error("each label needs a name (1-50 chars), six-digit color and description (0-100 chars)")
    key = label["name"].casefold()
    if key in seen:
        parser.error("duplicate label: " + label["name"])
    seen.add(key)
result = subprocess.run(
    ["gh", "api", "--paginate", "--slurp", f"repos/{args.repository}/labels?per_page=100"],
    check=True, capture_output=True, text=True,
)
existing = {label["name"].casefold(): label for page in json.loads(result.stdout) for label in page}
changed = 0
for label in labels:
    old = existing.get(label["name"].casefold())
    if old and old["name"] == label["name"] and old["color"].lower() == label["color"].lower() and (old.get("description") or "") == label["description"]:
        continue
    changed += 1
    verb = "update" if old else "create"
    print(f"{verb}: {label['name']}", flush=True)
    if args.apply:
        endpoint = f"repos/{args.repository}/labels"
        payload = dict(label)
        method = "POST"
        if old:
            from urllib.parse import quote
            endpoint += "/" + quote(old["name"], safe="")
            payload["new_name"] = payload.pop("name")
            method = "PATCH"
        subprocess.run(["gh", "api", "--method", method, endpoint, "--input", "-", "--silent"],
                       input=json.dumps(payload), text=True, check=True)
print(f"{changed} label changes {'applied' if args.apply else 'proposed'} for {args.repository}; undeclared labels preserved")
PYTHON
