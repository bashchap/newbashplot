#!/bin/bash
FILE="VROBI-legacy.cfg"

echo "# VROBI Legacy Computing Octant Mapping" > "$FILE"
echo "# Virtual Bit Mask (2x4):" >> "$FILE"
echo "# 1  | 16" >> "$FILE"
echo "# 2  | 32" >> "$FILE"
echo "# 4  | 64" >> "$FILE"
echo "# 8  | 128" >> "$FILE"

for i in {0..255}; do
    echo "nbp_VROBI_LEGACY[$i]=$i" >> "$FILE"
done

echo "Successfully generated $FILE"
