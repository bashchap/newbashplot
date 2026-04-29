#!/bin/bash
U_FILE="UnicodeCodePoint-x1CE00-x100-x1CEFF.cfg"
V_FILE="VROBI-legacy.cfg"

echo "# Generating LINEAR Unicode Mapping (0-255)..."
echo "# uCodePoint_LEGACY[offset]=\"Character\"" > "$U_FILE"

# Strictly iterate 0 to 255 to prevent jumps
for i in {0..255}; do
    # Calculate the exact hex address for each character
    hex_val=$(printf "%08x" $((0x1CE00 + i)))
    char=$(/usr/bin/printf "\U$hex_val")
    echo "uCodePoint_LEGACY[$i]=\"$char\"" >> "$U_FILE"
done

echo "# Generating BIT-MAPPED VROBI Mapping..."
echo "# Maps your 2x4 mask to Unicode Octant offsets" > "$V_FILE"

for i in {0..255}; do
    # 1. Extract your virtual bits from the index i
    # Left Column bits:
    B1=$(( (i >> 0) & 1 )) # Row 0, Left (Value 1)
    B2=$(( (i >> 1) & 1 )) # Row 1, Left (Value 2)
    B4=$(( (i >> 2) & 1 )) # Row 2, Left (Value 4)
    B8=$(( (i >> 3) & 1 )) # Row 3, Left (Value 8)
    # Right Column bits:
    B16=$(( (i >> 4) & 1 )) # Row 0, Right (Value 16)
    B32=$(( (i >> 5) & 1 )) # Row 1, Right (Value 32)
    B64=$(( (i >> 6) & 1 )) # Row 2, Right (Value 64)
    B128=$(( (i >> 7) & 1 )) # Row 3, Right (Value 128)

    # 2. Map to Unicode Octant Standard Bit-Weights:
    # Unicode: R0L=1, R1L=2, R2L=4, R0R=8, R1R=16, R2R=32, R3L=64, R3R=128
    u_offset=$(( (B1 << 0) | (B2 << 1) | (B4 << 2) | (B16 << 3) | (B32 << 4) | (B64 << 5) | (B8 << 6) | (B128 << 7) ))
    
    echo "nbp_VROBI_LEGACY[$i]=$u_offset" >> "$V_FILE"
done

echo "Verification: uCodePoint_LEGACY[255] should be the Full Block."
echo "Done."
