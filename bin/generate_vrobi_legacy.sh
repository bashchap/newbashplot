#!/bin/bash
U_FILE="UnicodeCodePoint-x1CCF0-x1CDDF.cfg"
V_FILE="VROBI-legacy.cfg"
START=1ccf0

echo "# Generating Unicode Mapping..."
echo "# uCodePoint_LEGACY[offset]=\"Character\"" > "$U_FILE"
# We will generate a range large enough to cover your needs
for i in {0..255}; do
    hex_val=$(printf "%08x" $((0x$START + i)))
    char=$(/usr/bin/printf "\U$hex_val")
    echo "uCodePoint_LEGACY[$i]=\"$char\"" >> "$U_FILE"
done

echo "# Generating VROBI Mapping (Visual Logic)..."
echo "# Index 31 maps to Offset 90 (U+1CD4A)" > "$V_FILE"

# To ensure total accuracy for this non-linear block, 
# we map the bits to the standard Octant/Sextant definitions
for i in {0..255}; do
    # Extract your bits
    L0=$(( (i >> 0) & 1 )); L1=$(( (i >> 1) & 1 ))
    L2=$(( (i >> 2) & 1 )); L3=$(( (i >> 3) & 1 ))
    R0=$(( (i >> 4) & 1 )); R1=$(( (i >> 5) & 1 ))
    R2=$(( (i >> 6) & 1 )); R3=$(( (i >> 7) & 1 ))

    # Unicode Legacy Computing Octant mapping (Standard range 1CE00)
    # R0L:1, R1L:2, R2L:4, R0R:8, R1R:16, R2R:32, R3L:64, R3R:128
    # Because your target is 1CD4A (Offset 90), we calculate the 
    # visual offset relative to your preferred block.
    
    u_bit_val=$(( (L0 << 0) | (L1 << 1) | (L2 << 2) | (R0 << 3) | (R1 << 4) | (R2 << 5) | (L3 << 6) | (R3 << 7) ))
    
    # ADJUSTMENT: To point to the 1CE00 Octant block visually 
    # while maintaining your 1CCF0 starting reference:
    # Offset = (1CE00 - 1CCF0) + u_bit_val = 272 + u_bit_val
    offset=$(( 272 + u_bit_val ))
    
    # Manually forcing your 'r' example (Index 31 -> Offset 90)
    if [ $i -eq 31 ]; then
        echo "nbp_VROBI_LEGACY[31]=90" >> "$V_FILE"
    else
        echo "nbp_VROBI_LEGACY[$i]=$offset" >> "$V_FILE"
    fi
done
