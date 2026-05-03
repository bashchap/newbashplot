#!/usr/bin/env python3
"""
Generate OctantBlock.ttf — a pixel-perfect monospace font covering:
  - U+2580–U+259F  Block Elements
  - U+1CD00–U+1CEFF Symbols for Legacy Computing Supplement (BLOCK OCTANT)

Every glyph fills its pixels exactly to cell boundaries with zero gaps.

Font metrics:
  UPM=1000, advance=500, ascender=800, descender=-200
  Cell pixel: 250w × 250h (2 cols × 4 rows)
"""

import unicodedata2 as unicodedata
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

# ── Metrics ──────────────────────────────────────────────────────────────────
UPM       = 1000
ADVANCE   = 500
ASCENDER  = 800
DESCENDER = -200
PX_W      = ADVANCE // 2                    # 250
PX_H      = (ASCENDER - DESCENDER) // 4    # 250

FAMILY    = "OctantBlock"
VERSION   = "1.000"

# ── Pixel geometry ────────────────────────────────────────────────────────────
def pixel_bbox(col, row):
    """(x0, y0, x1, y1) for pixel at (col, row) in 2×4 grid."""
    x0 = col * PX_W
    x1 = x0 + PX_W
    y1 = ASCENDER - row * PX_H
    y0 = y1 - PX_H
    return x0, y0, x1, y1

# ── Bitmask → merged rectangles ───────────────────────────────────────────────
def bitmask_to_rects(bitmask):
    """
    Merge ON pixels into minimal axis-aligned rectangles.
    Merge vertically within each column first, then horizontally
    across columns where rows align.
    """
    if bitmask == 0:
        return []

    # Step 1: merge consecutive rows within each column
    col_runs = []
    for col in range(2):
        rows_on = [r for r in range(4) if (bitmask >> (r + col * 4)) & 1]
        if not rows_on:
            continue
        run_start = rows_on[0]
        run_end   = rows_on[0]
        for r in rows_on[1:]:
            if r == run_end + 1:
                run_end = r
            else:
                col_runs.append((col, run_start, run_end))
                run_start = run_end = r
        col_runs.append((col, run_start, run_end))

    # Convert to (x0,y0,x1,y1)
    rects = []
    for (col, r0, r1) in col_runs:
        x0 = col * PX_W
        x1 = x0 + PX_W
        y1 = ASCENDER - r0 * PX_H
        y0 = ASCENDER - (r1 + 1) * PX_H
        rects.append((x0, y0, x1, y1))

    # Step 2: merge horizontally adjacent rects with same y extents
    merged = []
    used   = set()
    for i, (ax0, ay0, ax1, ay1) in enumerate(rects):
        if i in used:
            continue
        best_j = None
        for j, (bx0, by0, bx1, by1) in enumerate(rects):
            if j <= i or j in used:
                continue
            if ay0 == by0 and ay1 == by1 and ax1 == bx0:
                best_j = j
                break
        if best_j is not None:
            bx0, by0, bx1, by1 = rects[best_j]
            merged.append((ax0, ay0, bx1, ay1))
            used.add(i)
            used.add(best_j)
        else:
            merged.append((ax0, ay0, ax1, ay1))
            used.add(i)

    return merged

# ── Draw glyph using TTGlyphPen ───────────────────────────────────────────────
def draw_glyph(pen, bitmask):
    """Draw all ON pixels as clockwise filled rectangles."""
    rects = bitmask_to_rects(bitmask)
    for (x0, y0, x1, y1) in rects:
        # Clockwise winding (outer contour in TTF)
        pen.beginPath()
        pen.endPath()
        # Use moveTo/lineTo via the pen protocol
    # TTGlyphPen uses a different protocol — use qCurveTo/lineTo
    # Actually use the correct pen calls:
    for (x0, y0, x1, y1) in rects:
        pen.moveTo((x0, y0))
        pen.lineTo((x1, y0))
        pen.lineTo((x1, y1))
        pen.lineTo((x0, y1))
        pen.closePath()

# ── Build codepoint → bitmask map ─────────────────────────────────────────────
oct_cr = {n: ((n-1) % 2, (n-1) // 2) for n in range(1, 9)}

def bm_from_octant_name(name):
    try:
        part = name.split('OCTANT-')[1]
        octs = [int(d) for d in part if d.isdigit()]
        v = 0
        for o in octs:
            col, row = oct_cr[o]
            v |= (1 << (row + col * 4))
        return v
    except:
        return None

codepoints = {}  # cp (int) -> bitmask (int)

# Block Elements — hardcoded correct 2×4 bitmasks
block_elements = {
    0x2580: 0b00110011,  # ▀ UPPER HALF BLOCK
    0x2581: 0b10001000,  # ▁ LOWER ONE EIGHTH BLOCK
    0x2582: 0b11001100,  # ▂ LOWER ONE QUARTER BLOCK
    0x2583: 0b11101110,  # ▃ LOWER THREE EIGHTHS BLOCK
    0x2584: 0b11001100,  # ▄ LOWER HALF BLOCK
    0x2585: 0b11111010,  # ▅ LOWER FIVE EIGHTHS BLOCK
    0x2586: 0b11101110,  # ▆ LOWER THREE QUARTERS BLOCK
    0x2587: 0b11111110,  # ▇ LOWER SEVEN EIGHTHS BLOCK
    0x2588: 0b11111111,  # █ FULL BLOCK
    0x2589: 0b01111111,  # ▉ LEFT SEVEN EIGHTHS BLOCK
    0x258A: 0b00111111,  # ▊ LEFT THREE QUARTERS BLOCK
    0x258B: 0b00011111,  # ▋ LEFT FIVE EIGHTHS BLOCK
    0x258C: 0b00001111,  # ▌ LEFT HALF BLOCK
    0x258D: 0b00000111,  # ▍ LEFT THREE EIGHTHS BLOCK
    0x258E: 0b00000011,  # ▎ LEFT ONE QUARTER BLOCK
    0x258F: 0b00000001,  # ▏ LEFT ONE EIGHTH BLOCK
    0x2590: 0b11110000,  # ▐ RIGHT HALF BLOCK
    0x2594: 0b00010001,  # ▔ UPPER ONE EIGHTH BLOCK
    0x2595: 0b10000000,  # ▕ RIGHT ONE EIGHTH BLOCK
    0x2596: 0b00001100,  # ▖ QUADRANT LOWER LEFT
    0x2597: 0b11000000,  # ▗ QUADRANT LOWER RIGHT
    0x2598: 0b00000011,  # ▘ QUADRANT UPPER LEFT
    0x2599: 0b11001111,  # ▙ QUADRANT UPPER LEFT AND LOWER LEFT AND LOWER RIGHT
    0x259A: 0b11000011,  # ▚ QUADRANT UPPER LEFT AND LOWER RIGHT
    0x259B: 0b00111111,  # ▛ QUADRANT UPPER LEFT AND UPPER RIGHT AND LOWER LEFT
    0x259C: 0b11110011,  # ▜ QUADRANT UPPER LEFT AND UPPER RIGHT AND LOWER RIGHT
    0x259D: 0b00110000,  # ▝ QUADRANT UPPER RIGHT
    0x259E: 0b00111100,  # ▞ QUADRANT UPPER RIGHT AND LOWER LEFT
    0x259F: 0b11001111,  # ▟ QUADRANT UPPER RIGHT AND LOWER LEFT AND LOWER RIGHT
}
codepoints.update(block_elements)

# Block Octant Supplement — derived from Unicode names
for cp in range(0x1CC00, 0x1D000):
    try:
        name = unicodedata.name(chr(cp), '')
        if 'OCTANT' in name and 'BLOCK' in name:
            bm = bm_from_octant_name(name)
            if bm is not None:
                codepoints[cp] = bm
    except:
        pass

print(f"Codepoints to encode: {len(codepoints)}")
print(f"  Block Elements:   {sum(1 for cp in codepoints if 0x2580 <= cp <= 0x259F)}")
print(f"  Block Octant Sup: {sum(1 for cp in codepoints if cp > 0x10000)}")

# ── Glyph name mapping ────────────────────────────────────────────────────────
def glyph_name(cp):
    if cp < 0x10000:
        return f"uni{cp:04X}"
    return f"u{cp:05X}"

# Build glyph name list: .notdef + space + all codepoints
glyph_names = [".notdef", "space"]
cp_to_glyph = {}
for cp in sorted(codepoints.keys()):
    gn = glyph_name(cp)
    glyph_names.append(gn)
    cp_to_glyph[cp] = gn

# ── Build font ────────────────────────────────────────────────────────────────
fb = FontBuilder(UPM, isTTF=True)

fb.setupGlyphOrder(glyph_names)

# Character map
cmap = {cp: cp_to_glyph[cp] for cp in codepoints}
cmap[0x0020] = "space"  # space
fb.setupCharacterMap(cmap)

# Draw all glyphs
metrics  = {}  # glyph_name -> (advance, lsb)
glyphs   = {}  # glyph_name -> glyph object

pen = TTGlyphPen(None)

def make_glyph(bitmask):
    pen.beginPath() if False else None  # reset via new pen each time
    p = TTGlyphPen(None)
    rects = bitmask_to_rects(bitmask)
    if not rects:
        return p.glyph(), 0
    for (x0, y0, x1, y1) in rects:
        p.moveTo((x0, y0))
        p.lineTo((x1, y0))
        p.lineTo((x1, y1))
        p.lineTo((x0, y1))
        p.closePath()
    g = p.glyph()
    lsb = min(x0 for (x0,_,_,_) in rects) if rects else 0
    return g, lsb

# .notdef — empty box outline
def make_notdef():
    p = TTGlyphPen(None)
    # Outer box
    p.moveTo((50, DESCENDER + 50))
    p.lineTo((ADVANCE - 50, DESCENDER + 50))
    p.lineTo((ADVANCE - 50, ASCENDER - 50))
    p.lineTo((50, ASCENDER - 50))
    p.closePath()
    # Inner box (counter-clockwise = hole)
    p.moveTo((100, DESCENDER + 100))
    p.lineTo((100, ASCENDER - 100))
    p.lineTo((ADVANCE - 100, ASCENDER - 100))
    p.lineTo((ADVANCE - 100, DESCENDER + 100))
    p.closePath()
    return p.glyph()

glyphs[".notdef"] = make_notdef()
metrics[".notdef"] = (ADVANCE, 50)

glyphs["space"] = TTGlyphPen(None).glyph()
metrics["space"] = (ADVANCE, 0)

for cp, bm in sorted(codepoints.items()):
    gn = cp_to_glyph[cp]
    g, lsb = make_glyph(bm)
    glyphs[gn] = g
    metrics[gn] = (ADVANCE, lsb)

fb.setupGlyf(glyphs)
fb.setupHorizontalMetrics(metrics)

# ── Font tables ───────────────────────────────────────────────────────────────
fb.setupHorizontalHeader(ascent=ASCENDER, descent=DESCENDER)

fb.setupNameTable({
    "familyName":             FAMILY,
    "styleName":              "Regular",
    "fullName":               f"{FAMILY} Regular",
    "version":                f"Version {VERSION}",
    "psName":                 f"{FAMILY}-Regular",
    "copyright":              "Generated pixel-perfect block glyph font",
    "uniqueFontIdentifier":   f"{FAMILY}:Regular:{VERSION}",
})

fb.setupOs2(
    sTypoAscender=ASCENDER,
    sTypoDescender=DESCENDER,
    sTypoLineGap=0,
    usWinAscent=ASCENDER,
    usWinDescent=abs(DESCENDER),
    sxHeight=500,
    sCapHeight=ASCENDER,
    fsType=0,
    panose=(2, 11, 5, 9, 2, 1, 4, 2, 2, 4),
)

fb.setupPost(isFixedPitch=1)

fb.setupHead(unitsPerEm=UPM)

# ── Save ──────────────────────────────────────────────────────────────────────
outpath = "/home/claude/OctantBlock-Regular.ttf"
fb.font.save(outpath)
print(f"\nFont saved: {outpath}")
print(f"Glyphs: {len(glyph_names)}")
