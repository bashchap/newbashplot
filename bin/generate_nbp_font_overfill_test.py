#!/usr/bin/env fontforge
# Generate NewBashPlot private-use 2x4 plotting font and Bash glyph map.
# Output only. Does not install fonts or modify terminal settings.

import os
import sys
import fontforge
import psMat

OUTDIR = os.path.abspath("./build")
FONT_NAME = "NewBashPlotOverfill"
TTF_PATH = os.path.join(OUTDIR, "NewBashPlotOverfill.ttf")
MAP_PATH = os.path.join(OUTDIR, "nbp_VROBI_private_use_assignments.txt")

# Font cell geometry.
# 2 columns x 4 rows.
CELL_W = 800
CELL_H = 1600
COL_W = CELL_W // 2
ROW_H = CELL_H // 4

# Private Use Area base.
PUA_BASE = 0xE000

def bit_is_set(mask: int, bit_value: int) -> bool:
    return (mask & bit_value) != 0

def draw_rect(pen, x0, y0, x1, y1):
    """
    Draw filled rectangle using an existing glyph pen.
    """
    pen.moveTo((x0, y0))
    pen.lineTo((x1, y0))
    pen.lineTo((x1, y1))
    pen.lineTo((x0, y1))
    pen.closePath()
def draw_rect(pen, x0, y0, x1, y1):
    """
    Draw filled rectangle using an existing glyph pen.
    """
    pen.moveTo((x0, y0))
    pen.lineTo((x1, y0))
    pen.lineTo((x1, y1))
    pen.lineTo((x0, y1))
    pen.closePath()
def main():
    os.makedirs(OUTDIR, exist_ok=True)

    font = fontforge.font()
    font.fontname = FONT_NAME
    font.familyname = FONT_NAME
    font.fullname = FONT_NAME
    font.encoding = "UnicodeFull"

    # Vertical metrics.
    font.em = CELL_H
    font.ascent = CELL_H
    font.descent = 0

    # Basic recommended metadata.
    font.version = "1.0"
    font.copyright = "Generated locally for NewBashPlot."

    # Bit positions:
    # 0 4
    # 1 5
    # 2 6
    # 3 7
    #
    # Bit values:
    # 1   16
    # 2   32
    # 4   64
    # 8   128

    for mask in range(256):
        codepoint = PUA_BASE + mask
        glyph = font.createChar(codepoint, f"nbp_{mask:03d}")
        glyph.width = CELL_W

        pen = glyph.glyphPen()

        for row in range(4):
            for col in range(2):
                bit_value = (1 << row) << (col * 4)

                if not bit_is_set(mask, bit_value):
                    continue

                x0 = col * COL_W
                x1 = x0 + COL_W

# Test only: deliberately overfill horizontally
# while keeping glyph advance width unchanged.
                x0 -= 120
                x1 += 120

                # Logical top row 0 maps to highest y range.
                y_top = CELL_H - (row * ROW_H)
                y_bottom = y_top - ROW_H

                draw_rect(pen, x0, y_bottom, x1, y_top)

        glyph.removeOverlap()
        glyph.correctDirection()

        # Force identical terminal-cell advance width after all outline operations.
        glyph.width = CELL_W
        glyph.vwidth = CELL_H

    # Add a visible fallback/notdef box.
    notdef = font.createChar(-1, ".notdef")
    notdef.width = CELL_W
    pen = notdef.glyphPen()
    pen.moveTo((50, 50))
    pen.lineTo((CELL_W - 50, 50))
    pen.lineTo((CELL_W - 50, CELL_H - 50))
    pen.lineTo((50, CELL_H - 50))
    pen.closePath()
    notdef.width = CELL_W
    notdef.vwidth = CELL_H

    # Generate font.
    font.generate(TTF_PATH)

    # Generate Bash assignment file.
    with open(MAP_PATH, "w", encoding="utf-8") as f:
        f.write("# Generated NewBashPlot private-use glyph map\n")
        f.write("# Each index is the visual 2x4 bitmask.\n")
        f.write("# Glyph = U+E000 + bitmask.\n\n")
        for mask in range(256):
            char = chr(PUA_BASE + mask)
            f.write(f'nbp_VROBI[{mask}]="{char}" # U+{PUA_BASE + mask:04X}\n')

    print("Generated:")
    print(f"  {TTF_PATH}")
    print(f"  {MAP_PATH}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
