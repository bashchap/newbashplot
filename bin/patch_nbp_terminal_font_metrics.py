#!/usr/bin/env python3
from fontTools.ttLib import TTFont
import os
import shutil

SRC = "./build/NewBashPlotTerminal.ttf"
DST = "./build/NewBashPlotTerminalPatched.ttf"
REPORT = "./build/NewBashPlotTerminalPatched_report.txt"

UNITS_PER_EM = 1600
ADVANCE_WIDTH = 800
ASCENT = 1280
DESCENT = 320

TEST_CODEPOINTS = [0x20, 0x41, 0xE000, 0xE001, 0xE00F, 0xE0F0, 0xE0FF]

def glyph_bounds(font, glyph_name):
    glyf = font["glyf"]
    glyph = glyf[glyph_name]
    if glyph.isComposite():
        glyph.recalcBounds(glyf)
    elif glyph.numberOfContours != 0:
        glyph.recalcBounds(glyf)

    if glyph.numberOfContours == 0:
        return (0, 0, 0, 0)

    return (glyph.xMin, glyph.yMin, glyph.xMax, glyph.yMax)

def collect_metrics(path):
    font = TTFont(path)
    cmap = font.getBestCmap()
    lines = []

    lines.append(f"FILE: {path}")
    lines.append(f"exists: {os.path.exists(path)}")
    lines.append(f"size: {os.path.getsize(path) if os.path.exists(path) else 'missing'}")

    head = font["head"]
    hhea = font["hhea"]
    os2 = font["OS/2"]
    post = font["post"]

    lines.append("")
    lines.append("head:")
    for k in ["unitsPerEm", "xMin", "yMin", "xMax", "yMax", "lowestRecPPEM", "flags"]:
        lines.append(f"  {k}: {getattr(head, k)}")

    lines.append("")
    lines.append("hhea:")
    for k in [
        "ascent", "descent", "lineGap",
        "advanceWidthMax", "minLeftSideBearing",
        "minRightSideBearing", "xMaxExtent",
        "numberOfHMetrics"
    ]:
        lines.append(f"  {k}: {getattr(hhea, k)}")

    lines.append("")
    lines.append("OS/2:")
    for k in [
        "version", "xAvgCharWidth", "usWeightClass", "usWidthClass",
        "sTypoAscender", "sTypoDescender", "sTypoLineGap",
        "usWinAscent", "usWinDescent",
        "fsSelection", "usDefaultChar", "usBreakChar", "usMaxContext"
    ]:
        lines.append(f"  {k}: {getattr(os2, k, None)}")

    lines.append("")
    lines.append("post:")
    for k in ["isFixedPitch", "underlinePosition", "underlineThickness"]:
        lines.append(f"  {k}: {getattr(post, k)}")

    lines.append("")
    lines.append("selected glyphs:")
    for cp in TEST_CODEPOINTS:
        name = cmap.get(cp)
        if name is None:
            lines.append(f"  U+{cp:04X}: missing")
            continue

        aw, lsb = font["hmtx"][name]
        bounds = glyph_bounds(font, name)
        lines.append(
            f"  U+{cp:04X} {name}: "
            f"advanceWidth={aw}, leftSideBearing={lsb}, bounds={bounds}"
        )

    font.close()
    return "\n".join(lines)

def patch_font():
    if not os.path.exists(SRC):
        raise SystemExit(f"ERROR: missing source font: {SRC}")

    shutil.copy2(SRC, DST)

    font = TTFont(DST)

    head = font["head"]
    hhea = font["hhea"]
    os2 = font["OS/2"]
    post = font["post"]

    # head table: global font box should match plotting glyph maximum box.
    head.unitsPerEm = UNITS_PER_EM
    head.xMin = 0
    head.yMin = -DESCENT
    head.xMax = ADVANCE_WIDTH
    head.yMax = ASCENT
    head.lowestRecPPEM = 8

    # hhea table: terminal-friendly vertical metrics.
    hhea.ascent = ASCENT
    hhea.descent = -DESCENT
    hhea.lineGap = 0
    hhea.advanceWidthMax = ADVANCE_WIDTH
    hhea.minLeftSideBearing = 0
    hhea.minRightSideBearing = 0
    hhea.xMaxExtent = ADVANCE_WIDTH

    # OS/2 table: terminal-friendly vertical metrics.
    os2.xAvgCharWidth = ADVANCE_WIDTH
    os2.usWidthClass = 5
    os2.sTypoAscender = ASCENT
    os2.sTypoDescender = -DESCENT
    os2.sTypoLineGap = 0
    os2.usWinAscent = ASCENT
    os2.usWinDescent = DESCENT

    # Set USE_TYPO_METRICS bit in fsSelection if OS/2 version supports it.
    # Bit 7 = 128.
    os2.fsSelection = os2.fsSelection | 128

    # Mark fixed pitch.
    post.isFixedPitch = 1

    # Save with recalculated checksums.
    font.save(DST)
    font.close()

def main():
    os.makedirs("./build", exist_ok=True)

    before = collect_metrics(SRC)
    patch_font()
    after = collect_metrics(DST)

    with open(REPORT, "w", encoding="utf-8") as f:
        f.write("NewBashPlotTerminal metrics patch report\n")
        f.write("\n")
        f.write("=" * 80 + "\n")
        f.write("BEFORE\n")
        f.write("=" * 80 + "\n")
        f.write(before)
        f.write("\n\n")
        f.write("=" * 80 + "\n")
        f.write("AFTER\n")
        f.write("=" * 80 + "\n")
        f.write(after)
        f.write("\n")

    print(f"Wrote patched font: {DST}")
    print(f"Wrote report: {REPORT}")

if __name__ == "__main__":
    main()
