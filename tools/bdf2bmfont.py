#!/usr/bin/env python3
"""Convert X11 BDF bitmap fonts to AngelCode BMFont (.fnt + .png) for Godot.

Bits'n'Picas can read BDF, but its ``fnt`` output is the Windows 3.x FNT
format, which Godot's ``font_data_bmfont`` importer cannot use.  This script
writes the BMFont text format directly, preserving the BDF bitmaps and metrics
one-to-one.

Usage:
    python3 tools/bdf2bmfont.py assets/fonts/times/*.bdf

For the Times assets, add one pixel of line height and raise the glyphs by the
same amount so that the baseline underline sits one pixel lower relative to the
text:

    python3 tools/bdf2bmfont.py --line-height-adjust 1 assets/fonts/times/*.bdf
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path

ATLAS_WIDTHS = (128, 256, 512, 1024)
MAX_ATLAS_HEIGHT = 2048
PADDING = 1


@dataclass
class Glyph:
    codepoint: int
    width: int
    height: int
    x_offset: int
    y_offset: int
    advance: int
    # Row-major, 0/1 per pixel, length width * height.
    bits: bytearray


@dataclass
class ParsedFont:
    props: dict[str, str]
    glyphs: list[Glyph]


def parse_bdf(path: Path) -> ParsedFont:
    lines = path.read_bytes().decode("latin-1").splitlines()
    props: dict[str, str] = {}
    glyphs: list[Glyph] = []
    current: dict | None = None
    index = 0

    while index < len(lines):
        line = lines[index].strip()
        if not line:
            index += 1
            continue

        key, _, rest = line.partition(" ")
        rest = rest.strip()

        if key == "STARTCHAR":
            current = {
                "encoding": -1,
                "advance": None,
                "bbx": (0, 0, 0, 0),
                "bits": bytearray(),
            }
            index += 1
            continue

        if current is None:
            if key == "FONT":
                props["FONT"] = rest
            elif key in {
                "SIZE",
                "FONTBOUNDINGBOX",
                "FONT_ASCENT",
                "FONT_DESCENT",
                "PIXEL_SIZE",
                "FAMILY_NAME",
                "WEIGHT_NAME",
                "SLANT",
            }:
                props[key] = rest.strip('"')
            index += 1
            continue

        if key == "ENCODING":
            current["encoding"] = int(rest.split()[0])
        elif key == "DWIDTH":
            current["advance"] = int(rest.split()[0])
        elif key == "BBX":
            current["bbx"] = tuple(int(value) for value in rest.split()[:4])
        elif key == "BITMAP":
            width, height, _, _ = current["bbx"]
            byte_count = (width + 7) // 8
            bits = bytearray(width * height)
            for row in range(height):
                if index + 1 + row >= len(lines):
                    break
                hex_row = lines[index + 1 + row].strip()
                if len(hex_row) < byte_count * 2:
                    # BDF pads rows on the right to a whole byte.
                    hex_row = hex_row.ljust(byte_count * 2, "0")
                elif len(hex_row) > byte_count * 2:
                    hex_row = hex_row[: byte_count * 2]
                value = int(hex_row, 16) if hex_row else 0
                total_bits = byte_count * 8
                row_offset = row * width
                for x in range(width):
                    if value & (1 << (total_bits - 1 - x)):
                        bits[row_offset + x] = 1
            current["bits"] = bits
            index += height + 1
            continue
        elif key == "ENDCHAR":
            encoding = current["encoding"]
            if encoding >= 0:
                width, height, x_offset, y_offset = current["bbx"]
                advance = current["advance"]
                if advance is None:
                    advance = width
                glyphs.append(
                    Glyph(
                        codepoint=encoding,
                        width=width,
                        height=height,
                        x_offset=x_offset,
                        y_offset=y_offset,
                        advance=advance,
                        bits=current["bits"],
                    )
                )
            current = None

        index += 1

    if not glyphs:
        raise ValueError(f"{path}: no encoded glyphs found")
    return ParsedFont(props=props, glyphs=glyphs)


def font_metrics(props: dict[str, str]) -> tuple[int, int, int]:
    """Return (pixel_size, ascent, descent)."""
    size_text = props.get("PIXEL_SIZE")
    if not size_text:
        size_fields = props.get("SIZE", "").split()
        size_text = size_fields[0] if size_fields else ""
    if not size_text:
        raise ValueError("missing PIXEL_SIZE / SIZE property")
    pixel_size = int(size_text)

    if "FONT_ASCENT" in props and "FONT_DESCENT" in props:
        ascent = int(props["FONT_ASCENT"])
        descent = int(props["FONT_DESCENT"])
    else:
        _, height, _, y_offset = (
            int(value) for value in props["FONTBOUNDINGBOX"].split()[:4]
        )
        ascent = height + y_offset
        descent = -y_offset

    return pixel_size, ascent, descent


def font_face(props: dict[str, str]) -> tuple[str, bool, bool]:
    """Return (face name, bold, italic)."""
    family = props.get("FAMILY_NAME")
    weight = props.get("WEIGHT_NAME", "Regular")
    slant = props.get("SLANT", "R")

    if not family:
        fields = props.get("FONT", "").split("-")
        if len(fields) >= 5:
            family, weight, slant = fields[2], fields[3], fields[4]
        else:
            family = props.get("FONT") or "Bitmap Font"

    bold = "bold" in weight.lower() or weight.lower() in {
        "black",
        "demi",
        "heavy",
        "semibold",
    }
    italic = slant.upper() in {"I", "O"}

    parts = [family]
    if bold:
        parts.append("Bold")
    if italic:
        parts.append("Italic")
    return " ".join(parts), bold, italic


def filter_glyphs(glyphs: list[Glyph], mode: str) -> list[Glyph]:
    if mode == "ascii":
        return [glyph for glyph in glyphs if 0x20 <= glyph.codepoint <= 0x7E]
    if mode == "latin1":
        return [
            glyph
            for glyph in glyphs
            if 0x20 <= glyph.codepoint <= 0x7E
            or 0xA0 <= glyph.codepoint <= 0xFF
        ]
    return glyphs


def pack_atlas(glyphs: list[Glyph], width: int) -> tuple[list[tuple[Glyph, int, int]], int]:
    """Shelf-pack glyphs, returning placements and the atlas height."""
    drawable = sorted(
        (glyph for glyph in glyphs if glyph.width > 0 and glyph.height > 0),
        key=lambda glyph: (-glyph.height, -glyph.width, glyph.codepoint),
    )

    placements: list[tuple[Glyph, int, int]] = []
    x = 0
    y = 0
    row_height = 0

    for glyph in drawable:
        if x > 0 and x + glyph.width > width:
            y += row_height + PADDING
            x = 0
            row_height = 0
        placements.append((glyph, x, y))
        x += glyph.width + PADDING
        row_height = max(row_height, glyph.height)

    height = y + row_height if placements else 1
    return placements, height


def choose_atlas(
    glyphs: list[Glyph], requested_width: str
) -> tuple[int, int, list[tuple[Glyph, int, int]]]:
    max_width = max((glyph.width for glyph in glyphs), default=1)

    if requested_width != "auto":
        width = int(requested_width)
        if width < max_width:
            raise ValueError(
                f"atlas width {width} is smaller than the widest glyph ({max_width})"
            )
        placements, height = pack_atlas(glyphs, width)
        return width, height, placements

    best: tuple[int, int, list[tuple[Glyph, int, int]]] | None = None
    for width in ATLAS_WIDTHS:
        if width < max_width:
            continue
        placements, height = pack_atlas(glyphs, width)
        if height > MAX_ATLAS_HEIGHT:
            continue
        if best is None or width * height < best[0] * best[1]:
            best = (width, height, placements)

    if best is None:
        width = max(16, ((max_width + 7) // 8) * 8)
        placements, height = pack_atlas(glyphs, width)
        best = (width, height, placements)

    return best


def write_png(path: Path, width: int, height: int, pixels: bytearray) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(kind + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)

    raw = bytearray()
    for row in range(height):
        raw.append(0)  # PNG filter type: none
        raw += pixels[row * width : (row + 1) * width]

    header = struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def write_fnt(
    path: Path,
    *,
    face: str,
    size: int,
    bold: bool,
    italic: bool,
    ascent: int,
    line_height: int,
    line_height_adjust: int,
    atlas_width: int,
    atlas_height: int,
    image_name: str,
    glyphs: list[Glyph],
    positions: dict[int, tuple[int, int]],
) -> None:
    lines = [
        (
            f'info face="{face}" size={size} bold={int(bold)} italic={int(italic)} '
            'charset="" unicode=1 stretchH=100 smooth=0 aa=1 '
            "padding=1,1,1,1 spacing=0,0 outline=0"
        ),
        (
            f"common lineHeight={line_height + line_height_adjust} base={ascent} "
            f"scaleW={atlas_width} scaleH={atlas_height} pages=1 packed=0 "
            "alphaChnl=4 redChnl=0 greenChnl=0 blueChnl=0"
        ),
        f'page id=0 file="{image_name}"',
        f"chars count={len(glyphs)}",
    ]

    for glyph in sorted(glyphs, key=lambda glyph: glyph.codepoint):
        if glyph.width > 0 and glyph.height > 0:
            x, y = positions[glyph.codepoint]
            # Raising the glyphs by the line-height adjustment leaves the
            # baseline (and therefore the underline) lower relative to them.
            y_offset = ascent - (glyph.y_offset + glyph.height) - line_height_adjust
            lines.append(
                f"char id={glyph.codepoint} x={x} y={y} "
                f"width={glyph.width} height={glyph.height} "
                f"xoffset={glyph.x_offset} yoffset={y_offset} "
                f"xadvance={glyph.advance} page=0 chnl=15"
            )
        else:
            lines.append(
                f"char id={glyph.codepoint} x=0 y=0 width=0 height=0 "
                f"xoffset=0 yoffset=0 xadvance={glyph.advance} page=0 chnl=15"
            )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def convert(
    source: Path,
    *,
    out_dir: Path | None,
    glyph_mode: str,
    atlas_width: str,
    line_height_adjust: int,
    dry_run: bool,
) -> tuple[Path, int, int, int]:
    parsed = parse_bdf(source)
    glyphs = filter_glyphs(parsed.glyphs, glyph_mode)
    if not glyphs:
        raise ValueError(f"{source}: no glyphs left after filtering")

    size, ascent, descent = font_metrics(parsed.props)
    if ascent + descent + line_height_adjust <= 0:
        raise ValueError(
            f"{source}: line height adjustment {line_height_adjust} makes the line height non-positive"
        )
    face, bold, italic = font_face(parsed.props)
    width, height, placements = choose_atlas(glyphs, atlas_width)

    positions = {glyph.codepoint: (x, y) for glyph, x, y in placements}

    pixels = bytearray(width * height)
    for glyph, x, y in placements:
        for row in range(glyph.height):
            source_row = row * glyph.width
            target_row = (y + row) * width + x
            for column in range(glyph.width):
                if glyph.bits[source_row + column]:
                    pixels[target_row + column] = 255

    target_dir = out_dir if out_dir is not None else source.parent
    fnt_path = target_dir / f"{source.stem}.fnt"
    png_path = target_dir / f"{source.stem}.png"

    if not dry_run:
        target_dir.mkdir(parents=True, exist_ok=True)
        write_png(png_path, width, height, pixels)
        write_fnt(
            fnt_path,
            face=face,
            size=size,
            bold=bold,
            italic=italic,
            ascent=ascent,
            line_height=ascent + descent,
            line_height_adjust=line_height_adjust,
            atlas_width=width,
            atlas_height=height,
            image_name=png_path.name,
            glyphs=glyphs,
            positions=positions,
        )

    return fnt_path, len(glyphs), width, height


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Convert BDF bitmap fonts to AngelCode BMFont for Godot."
    )
    parser.add_argument("files", nargs="+", type=Path, help="BDF files to convert")
    parser.add_argument(
        "-o",
        "--out-dir",
        type=Path,
        help="write outputs here instead of next to each BDF",
    )
    parser.add_argument(
        "--atlas-width",
        choices=("auto", "128", "256", "512", "1024"),
        default="auto",
        help="atlas width in pixels (default: smallest area among the choices)",
    )
    parser.add_argument(
        "--line-height-adjust",
        type=int,
        default=0,
        metavar="PIXELS",
        help=(
            "add PIXELS to the line height and raise glyphs by the same amount "
            "(default: 0)"
        ),
    )
    encoding = parser.add_mutually_exclusive_group()
    encoding.add_argument("--ascii", action="store_true", help="keep U+0020-U+007E")
    encoding.add_argument("--latin1", action="store_true", help="keep Latin-1")
    parser.add_argument(
        "--dry-run", action="store_true", help="report sizes without writing files"
    )

    args = parser.parse_args(argv)
    glyph_mode = "ascii" if args.ascii else "latin1" if args.latin1 else "all"

    failures = 0
    for source in args.files:
        try:
            fnt_path, count, width, height = convert(
                source,
                out_dir=args.out_dir,
                glyph_mode=glyph_mode,
                atlas_width=args.atlas_width,
                line_height_adjust=args.line_height_adjust,
                dry_run=args.dry_run,
            )
        except (OSError, ValueError, KeyError) as error:
            print(f"{source}: {error}", file=sys.stderr)
            failures += 1
            continue

        suffix = " (dry run)" if args.dry_run else ""
        print(
            f"{source.name} -> {fnt_path.name} "
            f"({count} chars, {width}x{height} atlas){suffix}"
        )

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
