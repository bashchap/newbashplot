#!/usr/bin/env python3
import sys
import os
import subprocess
from fontTools.ttLib import TTFont

FONTS = [
    "./build/NewBashPlot.ttf",
    "./build/NewBashPlotOverfill.ttf",
    os.path.expanduser("~/.local/share/fonts/NewBashPlot.ttf"),
    os.path.expanduser("~/.local/share/fonts/NewBashPlotOverfill.ttf"),
]

CODEPOINTS = [0xE000, 0xE001, 0xE002, 0xE003, 0xE00F, 0xE0F0, 0xE0FF]

def run_cmd(cmd):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
        return out.rstrip()
    except Exception as e:
        return f"COMMAND_FAILED: {' '.join(cmd)}\n{e}"

def print_header(title):
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)

def inspect_font(path):
    print_header(f"FONT: {path}")

    if not os.path.exists(path):
        print("MISSING")
        return

    print(f"File size: {os.path.getsize(path)} bytes")

    print_header("fontconfig: fc-query")
    print(run_cmd(["fc-query", path]))

    print_header("fontconfig: fc-scan")
    print(run_cmd(["fc-scan", path]))

    print_header("fontconfig: fc-match by family")
    family_guess = os.path.basename(path).replace(".ttf", "")
    print(run_cmd(["fc-match", f"{family_guess}:style=Regular"]))

    print_header("TrueType tables")
    font = TTFont(path)

    print("Tables:", " ".join(font.keys()))

    # head table
    if "head" in font:
        h = font["head"]
        print_header("head")
        for attr in [
            "tableVersion", "fontRevision", "checkSumAdjustment", "magicNumber",
            "flags", "unitsPerEm", "xMin", "yMin", "xMax", "yMax",
            "macStyle", "lowestRecPPEM", "fontDirectionHint",
            "indexToLocFormat", "glyphDataFormat"
        ]:
            print(f"{attr}: {getattr(h, attr, None)}")

    # hhea table
    if "hhea" in font:
        h = font["hhea"]
        print_header("hhea")
        for attr in [
            "tableVersion", "ascent", "descent", "lineGap",
            "advanceWidthMax", "minLeftSideBearing", "minRightSideBearing",
            "xMaxExtent", "caretSlopeRise", "caretSlopeRun",
            "numberOfHMetrics"
        ]:
            print(f"{attr}: {getattr(h, attr, None)}")

    # OS/2 table
    if "OS/2" in font:
        o = font["OS/2"]
        print_header("OS/2")
        for attr in [
            "version", "xAvgCharWidth", "usWeightClass", "usWidthClass",
            "fsType", "ySubscriptXSize", "ySubscriptYSize",
            "ySuperscriptXSize", "ySuperscriptYSize",
            "yStrikeoutSize", "yStrikeoutPosition",
            "sTypoAscender", "sTypoDescender", "sTypoLineGap",
            "usWinAscent", "usWinDescent",
            "fsSelection", "sxHeight", "sCapHeight",
            "usDefaultChar", "usBreakChar", "usMaxContext"
        ]:
            print(f"{attr}: {getattr(o, attr, None)}")

    # post table
    if "post" in font:
        p = font["post"]
        print_header("post")
        for attr in [
            "formatType", "italicAngle", "underlinePosition",
            "underlineThickness", "isFixedPitch",
            "minMemType42", "maxMemType42", "minMemType1", "maxMemType1"
        ]:
            print(f"{attr}: {getattr(p, attr, None)}")

    # maxp
    if "maxp" in font:
        m = font["maxp"]
        print_header("maxp")
        for attr in [
            "tableVersion", "numGlyphs", "maxPoints", "maxContours",
            "maxCompositePoints", "maxCompositeContours",
            "maxZones", "maxTwilightPoints",
            "maxStorage", "maxFunctionDefs", "maxInstructionDefs",
            "maxStackElements", "maxSizeOfInstructions",
            "maxComponentElements", "maxComponentDepth"
        ]:
            print(f"{attr}: {getattr(m, attr, None)}")

    # cmap
    print_header("cmap coverage")
    cmap = font.getBestCmap()
    print(f"best cmap entries: {len(cmap) if cmap else 0}")
    for cp in CODEPOINTS:
        print(f"U+{cp:04X}: {cmap.get(cp) if cmap else None}")

    # hmtx and glyph bounds
    print_header("selected glyph metrics")
    glyf = font["glyf"] if "glyf" in font else None
    hmtx = font["hmtx"] if "hmtx" in font else None

    for cp in CODEPOINTS:
        name = cmap.get(cp) if cmap else None
        if not name:
            print(f"U+{cp:04X}: missing from cmap")
            continue

        aw, lsb = hmtx[name] if hmtx else (None, None)
        g = glyf[name] if glyf else None

        if g is not None:
            g.recalcBounds(glyf)
            bounds = (getattr(g, "xMin", None), getattr(g, "yMin", None),
                      getattr(g, "xMax", None), getattr(g, "yMax", None))
            contours = getattr(g, "numberOfContours", None)
        else:
            bounds = None
            contours = None

        print(
            f"U+{cp:04X} {name}: "
            f"advanceWidth={aw}, leftSideBearing={lsb}, "
            f"bounds={bounds}, contours={contours}"
        )

    font.close()

def main():
    report_path = "./build/nbp_font_metrics_report.txt"

    os.makedirs("./build", exist_ok=True)

    original_stdout = sys.stdout
    with open(report_path, "w", encoding="utf-8") as f:
        sys.stdout = f
        print("NewBashPlot font diagnostic report")
        print(f"Working directory: {os.getcwd()}")

        print_header("Environment")
        print(run_cmd(["date"]))
        print(run_cmd(["uname", "-a"]))
        print(run_cmd(["fc-match", "--version"]))
        print(run_cmd(["ttx", "--version"]))

        for path in FONTS:
            inspect_font(path)

    sys.stdout = original_stdout
    print(f"Wrote report: {report_path}")

if __name__ == "__main__":
    main()
