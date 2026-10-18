#!/usr/bin/env python3
"""Check that every link referenced by a request file exists in the directory."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_FILE = ROOT / "assets/data/data.json"
LEVELS_DIR = ROOT / "assets/data/levels"


def iter_entries(category: dict):
    yield from category.get("entries", [])
    for subcategory in category.get("subcategories", []):
        yield from iter_entries(subcategory)


def load_directory_links() -> set[str]:
    with DATA_FILE.open(encoding="utf-8") as file:
        data = json.load(file)

    links: set[str] = set()
    for category in data.get("categories", []):
        for entry in iter_entries(category):
            links.add(entry["link"])
    return links


def main() -> int:
    if not DATA_FILE.is_file():
        print(f"Missing directory data: {DATA_FILE.relative_to(ROOT)}", file=sys.stderr)
        return 1

    directory_links = load_directory_links()
    errors: list[str] = []
    request_files = sorted(LEVELS_DIR.glob("*.json"))

    for path in request_files:
        try:
            with path.open(encoding="utf-8") as file:
                data = json.load(file)
        except json.JSONDecodeError as error:
            errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {error}")
            continue

        for query in data.get("requests", []):
            links = query.get("links", [])
            if not links:
                errors.append(
                    f"{path.relative_to(ROOT)}: query {query.get('query')!r} has no links"
                )
                continue

            for link_data in links:
                link = link_data.get("link")
                if link not in directory_links:
                    errors.append(
                        f"{path.relative_to(ROOT)}: query {query.get('query')!r} "
                        f"references unknown link {link!r}"
                    )

    if errors:
        print("Invalid request links:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(
        f"Checked {len(request_files)} request file(s); all links exist in the directory."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
