#!/bin/bash
UNICODE_FILE="UnicodeCodePoint-x1CE00-x100-x1CEFF.cfg"
VROBI_FILE="VROBI-legacy.cfg"

echo "# Generating Unicode Mapping..."
echo "# uCodePoint_LEGACY[offset]=\"Character\"" > $UNICODE_FILE
for i in {0..255}; do
    hex_val=$(printf "%08x" $((0x1CE00 + i)))
    char=$(/usr/bin/printf "\U$hex_val")
    echo "uCodePoint_LEGACY[$i]=\"$char\"" >> $UNICODE_FILE
done

echo "# Generating Corrected VROBI Mapping..."
echo "# Maps your 2x4 mask to Unicode Octant offsets" > $VROBI_FILE
for i in {0..255}; do
    # Extract your bits based on your mask:
    # 1|16, 2|32, 4|64, 8|128
    B0=$(( (i >> 0) & 1 )) # Row 0, L (Val 1)
    B1=$(( (i >> 1) & 1 )) # Row 1, L (Val 2)
    B2=$(( (i >> 2) & 1 )) # Row 2, L (Val 4)
    B3=$(( (i >> 3) & 1 )) # Row 3, L (Val 8)
    B4=$(( (i >> 4) & 1 )) # Row 0, R (Val 16)
    B5=$(( (i >> 5) & 1 )) # Row 1, R (Val 32)
    B6=$(( (i >> 6) & 1 )) # Row 2, R (Val 64)
    B7=$(( (i >> 7) & 1 )) # Row 3, R (Val 128)

    # Re-assemble into Unicode's expected Octant bit-order:
    # Unicode: R0L(1), R1L(2), R2L(4), R0R(8), R1R(16), R2R(32), R3L(64), R3R(128)
    u_offset=$(( (B0 << 0) | (B1 << 1) | (B2 << 2) | (B4 << 3) | (B5 << 4) | (B6 << 5) | (B3 << 6) | (B7 << 7) ))
    
    echo "nbp_VROBI_LEGACY[$i]=$u_offset" >> $VROBI_FILE
done
echo "Done! Check your .cfg files."
