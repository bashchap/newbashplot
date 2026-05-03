There's too many potential issues debugging why there's vertical and horizontal seams/ artifacts during terminal rendering.

Think I need to:

Step 1:
Stop treating NewBashPlot font as a finished terminal font.

Step 2:
Modify the generator so NewBashPlot includes basic terminal characters:
  - space
  - ASCII printable range U+0020–U+007E
  - possibly newline is not a glyph, so not needed
  - optionally U+2588 for comparison/testing

Step 3:
Make those ASCII glyphs use the same advance width and sane metrics as the plotting glyphs.

Step 4:
Regenerate a new test font, for example:
  NewBashPlotTerminal.ttf

Step 5:
Programmatically inspect:
  - ASCII glyph metrics
  - U+E000–U+E0FF metrics
  - hhea / OS/2 line gap metrics
  - xterm acceptance
