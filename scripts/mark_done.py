#!/usr/bin/env python3
"""Sets a task or a slice to Done everywhere its status is recorded (guide 7.1).

    scripts/mark_done.py AND-008     task file, its epic's task table, BACKLOG.md
    scripts/mark_done.py EP-02.A     its epic's Slices table, BACKLOG.md

Run from anywhere in the repo. Fails, changing nothing, unless each place
holds exactly one status to change.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"


def one(paths: list[Path], what: str) -> Path:
    if len(paths) != 1:
        sys.exit(f"Expected one {what}, found {len(paths)}")
    return paths[0]


def set_row_done(text: str, item_id: str, where: Path) -> str:
    """The table row linking `item_id` ends with its status; set it to Done."""
    pattern = re.compile(r"^(\| \[" + re.escape(item_id) + r"[\]:][^\n]*\| )([^|\n]+?)( \|)$", re.MULTILINE)
    rows = pattern.findall(text)
    if len(rows) != 1:
        sys.exit(f"{where.relative_to(ROOT)}: expected one row for {item_id}, found {len(rows)}")
    return pattern.sub(r"\1Done\3", text)


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    item_id = sys.argv[1]
    changes: dict[Path, str] = {}

    if re.fullmatch(r"EP-\d+\.[A-Z]", item_id):
        epic = one(sorted((DOCS / "epics").glob(f"{item_id.split('.')[0]}-*.md")), f"epic for {item_id}")
    elif re.fullmatch(r"(SUP|IOS|AND)-\d+", item_id):
        task = one(sorted((DOCS / "tasks").glob(f"{item_id}-*.md")), f"task file for {item_id}")
        text = task.read_text()
        status = re.findall(r"^\| Status \| ([^|\n]+) \|$", text, re.MULTILINE)
        if len(status) != 1:
            sys.exit(f"{task.relative_to(ROOT)}: expected one Status field")
        changes[task] = re.sub(r"^\| Status \| [^|\n]+ \|$", "| Status | Done |", text, flags=re.MULTILINE)
        epic_id = re.search(r"^\| Epic \| (EP-\d+) \|$", text, re.MULTILINE)
        if not epic_id:
            sys.exit(f"{task.relative_to(ROOT)}: no Epic field")
        epic = one(sorted((DOCS / "epics").glob(f"{epic_id.group(1)}-*.md")), f"epic {epic_id.group(1)}")
    else:
        sys.exit(f"Not a task or slice ID: {item_id}")

    for path in (epic, DOCS / "BACKLOG.md"):
        changes[path] = set_row_done(path.read_text(), item_id, path)

    for path, text in changes.items():
        path.write_text(text)
        print(f"{item_id} Done in {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
