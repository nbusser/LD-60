#!/usr/bin/env python3
"""Check that directory and request links exist and have a valid URL format."""

from __future__ import annotations

import ipaddress
import json
import re
import sys
from collections.abc import Iterator
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent.parent
DATA_FILE = ROOT / "assets/data/data.json"
LEVELS_DIR = ROOT / "assets/data/levels"

ALLOWED_SCHEMES = {"http", "https"}
HOST_LABEL_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$")
URL_PART_RE = re.compile(r"^[A-Za-z0-9\-._~!$&'()*+,;=:@/%?]*$")
INVALID_PERCENT_RE = re.compile(r"%(?![0-9A-Fa-f]{2})")
SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*://")
COLON_PREFIX_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")


def iter_entries(
    category: dict[str, Any], path: tuple[str, ...] = ()
) -> Iterator[tuple[tuple[str, ...], dict[str, Any]]]:
    category_path = path + (category.get("name", "?"),)
    for entry in category.get("entries", []):
        yield category_path, entry
    for subcategory in category.get("subcategories", []):
        yield from iter_entries(subcategory, category_path)


def validate_link(link: Any) -> list[str]:
    """Return a list of reasons why *link* is not a valid URL.

    Links may be written with an optional http:// or https:// scheme. The game
    stores bare links such as "example.com/path", so both forms are accepted.
    """
    if not isinstance(link, str):
        return ["not a string"]
    if not link:
        return ["empty"]
    if link != link.strip():
        return ["leading or trailing whitespace"]
    if any(character.isspace() or ord(character) < 32 or ord(character) == 127 for character in link):
        return ["contains whitespace or control characters"]
    if "\\" in link:
        return ["contains a backslash"]
    if link.startswith("//"):
        return ["protocol-relative URLs are not allowed"]
    if "://" in link and not SCHEME_RE.match(link):
        return ["malformed scheme"]

    problems: list[str] = []

    if SCHEME_RE.match(link):
        try:
            parsed = urlsplit(link)
        except ValueError as error:
            return [f"invalid URL: {error}"]
        if parsed.scheme.lower() not in ALLOWED_SCHEMES:
            problems.append(
                f"unsupported scheme {parsed.scheme!r} "
                f"(expected http:// or https://)"
            )
    else:
        if COLON_PREFIX_RE.match(link):
            return ["missing // after the URL scheme"]
        try:
            parsed = urlsplit("//" + link)
        except ValueError as error:
            return [f"invalid URL: {error}"]

    if parsed.username is not None or parsed.password is not None:
        problems.append("user credentials are not allowed")

    host = parsed.hostname
    if not host:
        problems.append("missing host")
        return problems

    try:
        port = parsed.port
    except ValueError as error:
        problems.append(f"invalid port: {error}")
        port = None
    if port is not None and not 1 <= port <= 65535:
        problems.append("port must be between 1 and 65535")

    try:
        ipaddress.ip_address(host)
    except ValueError:
        if host.endswith("."):
            problems.append("host must not end with a dot")
        labels = host.split(".")
        if len(labels) < 2:
            problems.append("host is missing a top-level domain")
        for label in labels:
            if not HOST_LABEL_RE.fullmatch(label):
                problems.append(
                    f"host label {label!r} contains invalid characters"
                )
        if len(labels) >= 2:
            top_level_domain = labels[-1]
            if len(top_level_domain) < 2 or not (
                top_level_domain.isalpha() or top_level_domain.startswith("xn--")
            ):
                problems.append(
                    f"invalid top-level domain {top_level_domain!r}"
                )

    for part_name, value in (
        ("path", parsed.path),
        ("query", parsed.query),
        ("fragment", parsed.fragment),
    ):
        if not value:
            continue
        if not URL_PART_RE.fullmatch(value):
            problems.append(f"{part_name} contains invalid characters")
        if INVALID_PERCENT_RE.search(value):
            problems.append(f"{part_name} contains an invalid percent escape")

    return problems


def load_directory_links(errors: list[str]) -> tuple[set[str], int]:
    if not DATA_FILE.is_file():
        errors.append(f"Missing directory data: {DATA_FILE.relative_to(ROOT)}")
        return set(), 0

    with DATA_FILE.open(encoding="utf-8") as file:
        data = json.load(file)

    links: set[str] = set()
    entry_count = 0
    for category in data.get("categories", []):
        for category_path, entry in iter_entries(category):
            entry_count += 1
            link = entry.get("link")
            label = "/".join(category_path)
            problems = validate_link(link)
            if problems:
                errors.append(
                    f"data.json: entry {entry.get('name')!r} in {label!r} "
                    f"has invalid URL {link!r}: {', '.join(problems)}"
                )
            if isinstance(link, str) and link:
                links.add(link)
    return links, entry_count


def main() -> int:
    errors: list[str] = []

    directory_links, entry_count = load_directory_links(errors)
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
                problems = validate_link(link)
                if problems:
                    errors.append(
                        f"{path.relative_to(ROOT)}: query {query.get('query')!r} "
                        f"has invalid URL {link!r}: {', '.join(problems)}"
                    )
                    continue
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
        f"Checked {len(request_files)} request file(s) and {entry_count} "
        f"directory entries; all links exist and have a valid URL format."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
