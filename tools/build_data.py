#!/usr/bin/env python3
"""Build the game directory and level request files from the CSV sources.

Inputs:
    assets/data/data.csv
    assets/data/queries.csv

Outputs:
    assets/data/data.json
    assets/data/levels/level_<n>.json

The directory paths and query links are used exactly as written in the CSV.
Query links must match a directory entry link exactly, otherwise the build
fails and no files are written.
"""

from __future__ import annotations

import argparse
import csv
import difflib
import json
import re
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
DATA_CSV = ROOT / "assets/data/data.csv"
QUERIES_CSV = ROOT / "assets/data/queries.csv"
DATA_JSON = ROOT / "assets/data/data.json"
CATEGORY_ICONS_JSON = ROOT / "assets/data/category_icons.json"
CATEGORY_ICONS_DIR = ROOT / "assets/sprites/icons/categories"
CATEGORY_ICON_PREFIX = "res://assets/sprites/icons/categories/"
LEVELS_DIR = ROOT / "assets/data/levels"

DATA_HEADER = ("title", "description", "url", "image")
QUERIES_HEADER = ("query", "link", "score")


class CategoryNode:
    def __init__(self, name: str) -> None:
        self.name = name
        self.children: OrderedDict[str, CategoryNode] = OrderedDict()
        self.entries: list[dict[str, Any]] = []


def split_path(raw_path: str) -> list[str]:
    return [part.strip() for part in raw_path.split("/") if part.strip()]


def category_node(root: CategoryNode, parts: list[str]) -> CategoryNode:
    node = root
    for part in parts:
        node = node.children.setdefault(part, CategoryNode(part))
    return node


def load_category_icons(errors: list[str]) -> dict[str, str]:
    if not CATEGORY_ICONS_JSON.is_file():
        errors.append(
            f"Missing category icon mapping: {CATEGORY_ICONS_JSON.relative_to(ROOT)}"
        )
        return {}

    try:
        raw_icons = json.loads(CATEGORY_ICONS_JSON.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        errors.append(
            f"{CATEGORY_ICONS_JSON.relative_to(ROOT)}: invalid JSON: {error}"
        )
        return {}

    if not isinstance(raw_icons, dict):
        errors.append(
            f"{CATEGORY_ICONS_JSON.relative_to(ROOT)}: expected a JSON object"
        )
        return {}

    icons: dict[str, str] = {}
    for category, filename in raw_icons.items():
        if not isinstance(filename, str) or not filename:
            errors.append(
                f"{CATEGORY_ICONS_JSON.relative_to(ROOT)}: "
                f"invalid icon for category {category!r}"
            )
            continue
        if not (CATEGORY_ICONS_DIR / filename).is_file():
            errors.append(
                f"{CATEGORY_ICONS_JSON.relative_to(ROOT)}: "
                f"missing icon file {filename!r} for category {category!r}"
            )
            continue
        icons[category] = CATEGORY_ICON_PREFIX + filename
    return icons


def category_to_json(
    node: CategoryNode,
    path: list[str],
    icons: dict[str, str],
    errors: list[str],
) -> dict[str, Any]:
    full_path = "/".join(path)
    icon = icons.get(full_path)
    if icon is None:
        errors.append(f"Missing icon for category {full_path!r}")
    result: dict[str, Any] = {
        "name": node.name,
        "icon": icon,
    }
    if node.children:
        result["subcategories"] = [
            category_to_json(child, path + [child.name], icons, errors)
            for child in node.children.values()
        ]
    # Leaf categories always get an entries array, even when empty. Categories
    # that have both subcategories and direct entries get both keys.
    if node.entries or not node.children:
        result["entries"] = node.entries
    return result


def read_data_rows(
    errors: list[str], warnings: list[str]
) -> tuple[list[dict[str, Any]], list[list[str]]]:
    if not DATA_CSV.is_file():
        errors.append(f"Missing directory source: {DATA_CSV.relative_to(ROOT)}")
        return [], []

    entries: list[dict[str, Any]] = []
    category_paths: list[list[str]] = []
    with DATA_CSV.open(newline="", encoding="utf-8") as file:
        reader = csv.reader(file, delimiter=";")
        try:
            header = [cell.strip() for cell in next(reader)]
        except StopIteration:
            errors.append(f"{DATA_CSV.relative_to(ROOT)} is empty")
            return [], []

        missing = [name for name in DATA_HEADER if name not in header]
        path_columns = [i for i, name in enumerate(header) if name.startswith("path")]
        if missing:
            errors.append(
                f"{DATA_CSV.relative_to(ROOT)}: missing column(s) {', '.join(missing)}"
            )
            return [], []
        if not path_columns:
            errors.append(f"{DATA_CSV.relative_to(ROOT)}: missing path0/path1 columns")
            return [], []

        indexes = {name: header.index(name) for name in DATA_HEADER}

        for line_number, row in enumerate(reader, start=2):
            if not any(cell.strip() for cell in row):
                continue
            if len(row) < max(indexes.values()) + 1:
                errors.append(
                    f"{DATA_CSV.relative_to(ROOT)}:{line_number}: "
                    f"expected at least {max(indexes.values()) + 1} columns, "
                    f"got {len(row)}"
                )
                continue

            title = row[indexes["title"]].strip()
            description = row[indexes["description"]].strip()
            url = row[indexes["url"]].strip()
            image = row[indexes["image"]].strip()

            raw_paths = [
                row[index].strip()
                for index in path_columns
                if index < len(row) and row[index].strip()
            ]
            if not raw_paths:
                errors.append(
                    f"{DATA_CSV.relative_to(ROOT)}:{line_number}: "
                    f"entry {title!r} has no category path"
                )
                continue

            if not title:
                errors.append(
                    f"{DATA_CSV.relative_to(ROOT)}:{line_number}: empty title"
                )
                continue

            for raw_path in raw_paths:
                parts = split_path(raw_path)
                if not parts:
                    errors.append(
                        f"{DATA_CSV.relative_to(ROOT)}:{line_number}: "
                        f"invalid category path {raw_path!r}"
                    )
                    continue
                if len(parts) != len(raw_path.split("/")):
                    warnings.append(
                        f"{DATA_CSV.relative_to(ROOT)}:{line_number}: "
                        f"normalized category path {raw_path!r} "
                        f"to {'/'.join(parts)!r}"
                    )

                category_paths.append(parts)

                # A row without a URL only declares a category.
                if not url:
                    continue

                entries.append(
                    {
                        "name": title,
                        "path": parts,
                        "link": url,
                        "description": description,
                        "image": image or None,
                    }
                )

    return entries, category_paths


def build_directory(
    entries: list[dict[str, Any]],
    category_paths: list[list[str]],
    icons: dict[str, str],
    errors: list[str],
    warnings: list[str],
) -> dict[str, Any]:
    root = CategoryNode("")

    # Category-only rows still need to exist as empty leaves in the directory.
    for path in category_paths:
        category_node(root, path)

    for entry in entries:
        node = category_node(root, entry["path"])
        node.entries.append(
            {
                "name": entry["name"],
                "link": entry["link"],
                "description": entry["description"],
                "image": entry["image"],
            }
        )

    # Detect links reused with different content, which would make query
    # matching ambiguous.
    signatures: dict[str, tuple[Any, ...]] = {}
    for entry in entries:
        signature = (
            entry["name"],
            entry["description"],
            entry["image"],
        )
        previous = signatures.setdefault(entry["link"], signature)
        if previous != signature:
            errors.append(
                f"Directory link {entry['link']!r} is used by entries with "
                f"different names/descriptions"
            )

    # Exact paths only: warn when siblings differ only by case, since those
    # become separate categories in the directory.
    def check_case_duplicates(node: CategoryNode, path: str) -> None:
        folded: dict[str, list[str]] = defaultdict(list)
        for child in node.children.values():
            folded[child.name.casefold()].append(child.name)
        for names in folded.values():
            if len(names) > 1:
                warnings.append(
                    f"Category {path or '/'!r} has case-only duplicates: "
                    f"{', '.join(sorted(names))}"
                )
        for child in node.children.values():
            check_case_duplicates(
                child, f"{path}/{child.name}" if path else child.name
            )

    check_case_duplicates(root, "")

    categories = [
        category_to_json(child, [child.name], icons, errors)
        for child in root.children.values()
    ]
    return {"categories": categories}


def read_queries(
    entry_links: set[str], errors: list[str], warnings: list[str]
) -> OrderedDict[str, list[tuple[str, float]]]:
    groups: OrderedDict[str, list[tuple[str, float]]] = OrderedDict()

    if not QUERIES_CSV.is_file():
        errors.append(f"Missing query source: {QUERIES_CSV.relative_to(ROOT)}")
        return groups

    with QUERIES_CSV.open(newline="", encoding="utf-8") as file:
        reader = csv.reader(file, delimiter=";")
        try:
            header = [cell.strip() for cell in next(reader)]
        except StopIteration:
            errors.append(f"{QUERIES_CSV.relative_to(ROOT)} is empty")
            return groups

        missing = [name for name in QUERIES_HEADER if name not in header]
        if missing:
            errors.append(
                f"{QUERIES_CSV.relative_to(ROOT)}: missing column(s) "
                f"{', '.join(missing)}"
            )
            return groups

        indexes = {name: header.index(name) for name in QUERIES_HEADER}

        for line_number, row in enumerate(reader, start=2):
            if not any(cell.strip() for cell in row):
                continue
            if len(row) < len(QUERIES_HEADER):
                errors.append(
                    f"{QUERIES_CSV.relative_to(ROOT)}:{line_number}: "
                    f"expected {len(QUERIES_HEADER)} columns, got {len(row)}"
                )
                continue

            query = row[indexes["query"]].strip()
            link = row[indexes["link"]].strip()
            raw_score = row[indexes["score"]].strip()

            if not query:
                errors.append(
                    f"{QUERIES_CSV.relative_to(ROOT)}:{line_number}: empty query"
                )
                continue
            if not link:
                errors.append(
                    f"{QUERIES_CSV.relative_to(ROOT)}:{line_number}: "
                    f"query {query!r} has an empty link"
                )
                continue

            try:
                score = float(raw_score)
            except ValueError:
                errors.append(
                    f"{QUERIES_CSV.relative_to(ROOT)}:{line_number}: "
                    f"invalid score {raw_score!r} for query {query!r}"
                )
                continue
            if score < 0:
                errors.append(
                    f"{QUERIES_CSV.relative_to(ROOT)}:{line_number}: "
                    f"negative score {score!r} for query {query!r}"
                )
                continue

            if link not in entry_links:
                suggestions = difflib.get_close_matches(
                    link, sorted(entry_links), n=3, cutoff=0.4
                )
                suggestion_text = (
                    f" Closest directory link(s): {', '.join(repr(s) for s in suggestions)}."
                    if suggestions
                    else ""
                )
                errors.append(
                    f"{QUERIES_CSV.relative_to(ROOT)}:{line_number}: "
                    f"query {query!r} references unknown link {link!r}."
                    f"{suggestion_text}"
                )
                continue

            groups.setdefault(query, []).append((link, score))

    return groups


def split_requests(
    groups: OrderedDict[str, list[tuple[str, float]]],
    levels: int,
    first_time: float,
    interval: float,
    duration: float,
    points_scale: float,
    errors: list[str],
) -> list[list[dict[str, Any]]]:
    items = list(groups.items())
    if levels <= 0:
        errors.append("--levels must be greater than zero")
        return []
    if not items:
        errors.append("No valid queries found")
        return []
    if levels > len(items):
        errors.append(
            f"Cannot split {len(items)} query group(s) into {levels} level(s)"
        )
        return []
    if interval < 0:
        errors.append("--interval must not be negative")
        return []
    if duration < 0:
        errors.append("--duration must not be negative")
        return []
    if points_scale <= 0:
        errors.append("--points-scale must be greater than zero")
        return []

    base, remainder = divmod(len(items), levels)
    sizes = [
        base + (1 if index >= levels - remainder else 0) for index in range(levels)
    ]

    levels_data: list[list[dict[str, Any]]] = []
    item_index = 0
    for level_index, size in enumerate(sizes):
        requests: list[dict[str, Any]] = []
        for request_index, (query, links) in enumerate(
            items[item_index : item_index + size]
        ):
            requests.append(
                {
                    "time": first_time + request_index * interval,
                    "query": query,
                    "duration": duration,
                    "links": [
                        {
                            "link": link,
                            "points": int(round(score * points_scale)),
                        }
                        for link, score in links
                    ],
                }
            )
        item_index += size
        levels_data.append(requests)

    return levels_data


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent="\t", ensure_ascii=False) + "\n"
    path.write_text(text, encoding="utf-8")


def count_categories(categories: list[dict[str, Any]]) -> int:
    total = 0
    for category in categories:
        total += 1
        total += count_categories(category.get("subcategories", []))
    return total


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build assets/data/data.json and level request files."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate the CSV files without writing any output",
    )
    parser.add_argument(
        "--levels",
        type=int,
        default=5,
        help="number of level files to generate (default: 5)",
    )
    parser.add_argument(
        "--first-time",
        type=float,
        default=10.0,
        help="time of the first request in each level, in seconds (default: 10)",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=50.0,
        help="delay between requests, in seconds (default: 50)",
    )
    parser.add_argument(
        "--duration",
        type=float,
        default=55.0,
        help="request duration, in seconds (default: 55)",
    )
    parser.add_argument(
        "--points-scale",
        type=float,
        default=1.0,
        help="multiplier applied to the score column (default: 1)",
    )
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []

    entries, category_paths = read_data_rows(errors, warnings)
    icons = load_category_icons(errors)
    directory = build_directory(entries, category_paths, icons, errors, warnings)
    entry_links = {entry["link"] for entry in entries}
    groups = read_queries(entry_links, errors, warnings)
    levels_data = split_requests(
        groups,
        args.levels,
        args.first_time,
        args.interval,
        args.duration,
        args.points_scale,
        errors,
    )

    if errors:
        print("Cannot build game data:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        print(
            f"\n{len(errors)} error(s); no files were written.",
            file=sys.stderr,
        )
        return 1

    if not args.check:
        stale_pattern = re.compile(r"level_(\d+)\.json$")
        for level_path in sorted(LEVELS_DIR.glob("level_*.json")):
            match = stale_pattern.match(level_path.name)
            if match and int(match.group(1)) >= args.levels:
                warnings.append(
                    f"{level_path.relative_to(ROOT)} was not regenerated "
                    f"(only level_0..level_{args.levels - 1} are generated)"
                )

    for warning in warnings:
        print(f"Warning: {warning}", file=sys.stderr)

    categories = directory["categories"]
    request_count = sum(len(requests) for requests in levels_data)
    print(
        f"Directory: {len(entries)} entries, "
        f"{count_categories(categories)} categories"
    )
    print(
        f"Queries: {len(groups)} group(s), {request_count} request(s), "
        f"{args.levels} level(s)"
    )

    if args.check:
        print("Validation passed; no files written.")
        return 0

    write_json(DATA_JSON, directory)
    print(f"Wrote {DATA_JSON.relative_to(ROOT)}")

    for level_index, requests in enumerate(levels_data):
        level_path = LEVELS_DIR / f"level_{level_index}.json"
        write_json(level_path, {"requests": requests})
        print(f"Wrote {level_path.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
