#!/bin/bash
U_FILE="UnicodeCodePoint-x1CE00-x100-x1CEFF.cfg"
V_FILE="VROBI-legacy.cfg"

# 1. Generate the linear Unicode Table (0-255)
echo "# Unicode Mapping for Legacy Computing Octants" > "$U_FILE"
for i in {0..255}; do
    # Ensure 8-digit hex for the \U escape
    hex_val=$(printf "%08x" $((0x1CE00 + i)))
    char=$(/usr/bin/printf "\U$hex_val")
    echo "uCodePoint_LEGACY[$i]=\"$char\"" >> "$U_FILE"
done

# 2. Generate the VROBI map with Bit Shuffling
echo "# VROBI Legacy Mapping (Your 2x4 Mask -> Unicode)" > "$V_FILE"
for i in {0..255}; do
    # Extract your bits from index i
    L0=$(( (i >> 0) & 1 )) # bit 1
    L1=$(( (i >> 1) & 1 )) # bit 2
    L2=$(( (i >> 2) & 1 )) # bit 4
    L3=$(( (i >> 3) & 1 )) # bit 8
    R0=$(( (i >> 4) & 1 )) # bit 16
    R1=$(( (i >> 5) & 1 )) # bit 32
    R2=$(( (i >> 6) & 1 )) # bit 64
    R3=$(( (i >> 7) & 1 )) # bit 128

    # Re-map to Unicode bit positions
    # Unicode Octant bit weights:
    # 1:L0, 2:L1, 4:L2, 8:R0, 16:R1, 32:R2, 64:L3, 128:R3
    u_offset=$(( (L0 << 0) | (L1 << 1) | (L2 << 2) | (R0 << 3) | (R1 << 4) | (R2 << 5) | (L3 << 6) | (R3 << 7) ))
    
    echo "nbp_VROBI_LEGACY[$i]=$u_offset" >> "$V_FILE"
done

echo "Success: $U_FILE and $V_FILE generated."
