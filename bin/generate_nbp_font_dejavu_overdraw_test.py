#!/usr/bin/env fontforge
# Generate NewBashPlot private-use 2x4 plotting font and Bash glyph map.
# Output only. Does not install fonts or modify terminal settings.

import os
import sys
import fontforge
import psMat

OUTDIR = os.path.abspath("./build")
FONT_NAME = "NewBashPlotDejaVuOD"
TTF_PATH = os.path.join(OUTDIR, "NewBashPlotDejaVuOD.ttf")
MAP_PATH = os.path.join(OUTDIR, "nbp_VROBI_private_use_assignments.txt")

# Font cell geometry.
# 2 columns x 4 rows.
CELL_W = 800
CELL_H = 1600
ASCENT = 1280
DESCENT = 320
Y_SHIFT = -DESCENT

COL_W = CELL_W // 2
ROW_H = CELL_H // 4
X_OVERDRAW = 10

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
    font.ascent = ASCENT
    font.descent = DESCENT

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

# DejaVu U+2588 uses slight horizontal overdraw.
# For 800 advance width, 10 units approximates DejaVu's ratio.
                x0 -= X_OVERDRAW
                x1 += X_OVERDRAW

                # Logical top row 0 maps to highest y range.
                y_top = CELL_H - (row * ROW_H) + Y_SHIFT
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
    pen.moveTo((50, -270))
    pen.lineTo((CELL_W - 50, -270))
    pen.lineTo((CELL_W - 50, 1230))
    pen.lineTo((50, 1230))
    pen.closePath()
    notdef.width = CELL_W
    notdef.vwidth = CELL_H

        # Add minimal printable ASCII so the font can behave as a terminal font.
    # These are simple placeholder glyphs, not intended to be beautiful.
    # They give terminals valid ISO-8859-1/basic Latin coverage and sane metrics.
    for cp in range(0x20, 0x7F):
        if cp in font:
            continue

        glyph = font.createChar(cp, f"ascii_{cp:02X}")
        glyph.width = CELL_W
        glyph.vwidth = CELL_H

        # Space is intentionally blank.
        if cp == 0x20:
            continue

        # Draw a simple rectangular outline for visible ASCII placeholders.
        # This is only to make the font acceptable/readable enough for testing.
        pen = glyph.glyphPen()
        margin_x = CELL_W * 0.18
        margin_y = CELL_H * 0.18

        pen.moveTo((margin_x, margin_y + Y_SHIFT))
        pen.lineTo((CELL_W - margin_x, margin_y + Y_SHIFT))
        pen.lineTo((CELL_W - margin_x, CELL_H - margin_y + Y_SHIFT))
        pen.lineTo((margin_x, CELL_H - margin_y + Y_SHIFT))
        pen.closePath()

        glyph.correctDirection()
        glyph.width = CELL_W
        glyph.vwidth = CELL_H

    # Force stricter terminal-style metrics.
    # Use 80/20 ascent/descent split within the 1600 em square.
    font.ascent = 1280
    font.descent = 320

    font.hhea_ascent = 1280
    font.hhea_descent = -320
    font.hhea_linegap = 0

    font.os2_typoascent = 1280
    font.os2_typodescent = -320
    font.os2_typolinegap = 0
    font.os2_winascent = 1280
    font.os2_windescent = 320

    font.os2_use_typo_metrics = True

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
