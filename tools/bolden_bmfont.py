#!/usr/bin/env python3
"""Create a bold variant of an AngelCode BMFont by smearing glyphs horizontally.

Every ink pixel is duplicated one pixel to the right, which thickens vertical
stems without changing the glyph height or the pixel grid.  Glyph widths and
advances grow by one pixel so the spacing stays the same.

Usage:
    python3 tools/bolden_bmfont.py assets/fonts/w95fa_13.fnt
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from PIL import Image

PADDING = 1
ATLAS_WIDTH = 256


def next_pow2(value: int) -> int:
    return 1 << max(0, (value - 1).bit_length())


def read_font(path: Path) -> tuple[list[str], list[dict[str, int | str]]]:
    """Return the raw header lines and the parsed char records."""
    header: list[str] = []
    glyphs: list[dict[str, int | str]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("char "):
            glyphs.append(dict(re.findall(r"(\w+)=(-?\d+)", line)))
        elif line.startswith("kernings "):
            continue
        elif glyphs:
            raise ValueError(f"{path}: unexpected line after char records: {line!r}")
        else:
            header.append(line)
    return header, glyphs


def read_glyph(
    image: Image.Image, glyph: dict[str, int | str]
) -> list[list[bool]] | None:
    width = int(glyph["width"])
    height = int(glyph["height"])
    if width == 0 or height == 0:
        return None
    left = int(glyph["x"])
    top = int(glyph["y"])
    crop = image.crop((left, top, left + width, top + height))
    alpha = crop.getchannel("A")
    return [
        [alpha.getpixel((x, y)) > 0 for x in range(width)] for y in range(height)
    ]


def bolden(rows: list[list[bool]]) -> list[list[bool]]:
    """Set every ink pixel and the pixel immediately to its right."""
    height = len(rows)
    width = len(rows[0])
    result = [[False] * (width + 1) for _ in range(height)]
    for y in range(height):
        for x in range(width):
            if rows[y][x]:
                result[y][x] = True
                result[y][x + 1] = True
    return result


def pack(
    glyphs: list[dict[str, int | str]],
    rows: dict[int, list[list[bool]]],
    atlas_width: int,
) -> tuple[int, int, dict[int, tuple[int, int]]]:
    order = sorted(
        (glyph for glyph in glyphs if int(glyph["id"]) in rows),
        key=lambda glyph: (-len(rows[int(glyph["id"])]), -len(rows[int(glyph["id"])][0])),
    )
    positions: dict[int, tuple[int, int]] = {}
    x = y = PADDING
    shelf = 0
    for glyph in order:
        bitmap = rows[int(glyph["id"])]
        width = len(bitmap[0])
        height = len(bitmap)
        if x + width + PADDING > atlas_width:
            x = PADDING
            y += shelf + PADDING
            shelf = 0
        positions[int(glyph["id"])] = (x, y)
        x += width + PADDING
        shelf = max(shelf, height)
    return atlas_width, next_pow2(y + shelf + PADDING), positions


def write_atlas(
    path: Path,
    width: int,
    height: int,
    rows: dict[int, list[list[bool]]],
    positions: dict[int, tuple[int, int]],
) -> None:
    image = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    pixels = image.load()
    for codepoint, (left, top) in positions.items():
        for y, row in enumerate(rows[codepoint]):
            for x, inside in enumerate(row):
                if inside:
                    pixels[left + x, top + y] = (255, 255, 255, 255)
    image.save(path)


def write_fnt(
    path: Path,
    header: list[str],
    glyphs: list[dict[str, int | str]],
    rows: dict[int, list[list[bool]]],
    positions: dict[int, tuple[int, int]],
    atlas_width: int,
    atlas_height: int,
    page_file: str,
) -> None:
    info = header[0]
    info = re.sub(r'face="[^"]*"', 'face="W95FA Bold"', info)
    info = re.sub(r"bold=\d+", "bold=1", info)
    common = header[1]
    common = re.sub(r"scaleW=\d+", f"scaleW={atlas_width}", common)
    common = re.sub(r"scaleH=\d+", f"scaleH={atlas_height}", common)

    lines = [
        info,
        common,
        f'page id=0 file="{page_file}"',
        f"chars count={len(glyphs)}",
    ]
    for glyph in glyphs:
        codepoint = int(glyph["id"])
        if codepoint in rows:
            left, top = positions[codepoint]
            bitmap = rows[codepoint]
            lines.append(
                f"char id={codepoint} x={left} y={top} "
                f"width={len(bitmap[0])} height={len(bitmap)} "
                f"xoffset={glyph['xoffset']} yoffset={glyph['yoffset']} "
                f"xadvance={int(glyph['xadvance']) + 1} page=0 chnl=15"
            )
        else:
            lines.append(
                f"char id={codepoint} x=0 y=0 width=0 height=0 "
                f"xoffset=0 yoffset=0 xadvance={glyph['xadvance']} page=0 chnl=15"
            )
    lines.append("kernings count=0")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("font", help="source BMFont .fnt")
    parser.add_argument("--out", default=None, help="output .fnt path")
    parser.add_argument("--atlas-width", type=int, default=ATLAS_WIDTH)
    args = parser.parse_args()

    source = Path(args.font)
    header, glyphs = read_font(source)
    page_file = re.search(r'file="([^"]+)"', header[2]).group(1)
    image = Image.open(source.parent / page_file).convert("RGBA")

    rows: dict[int, list[list[bool]]] = {}
    for glyph in glyphs:
        bitmap = read_glyph(image, glyph)
        if bitmap is not None:
            rows[int(glyph["id"])] = bolden(bitmap)

    atlas_width, atlas_height, positions = pack(glyphs, rows, args.atlas_width)
    target = Path(args.out) if args.out else source.with_name(f"{source.stem}_bold.fnt")
    bold_page = f"{target.stem}.png"
    write_atlas(target.with_name(bold_page), atlas_width, atlas_height, rows, positions)
    write_fnt(
        target,
        header,
        glyphs,
        rows,
        positions,
        atlas_width,
        atlas_height,
        bold_page,
    )
    print(
        f"{target}: {len(rows)} glyphs, {atlas_width}x{atlas_height} atlas"
    )


if __name__ == "__main__":
    main()
