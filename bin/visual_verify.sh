#!/bin/bash

printf "%-6s | %-8s | %-8s | %-8s | %-10s\n" "Index" "Bitmask" "Braille" "Legacy" "Legacy Hex"
echo "------------------------------------------------------------"

for i in {0..255}; do
    # Extract your bits based on (2^y)<<(x*4)
    # Left Column (x=0)
    L0=$(( (i >> 0) & 1 )); L1=$(( (i >> 1) & 1 )); L2=$(( (i >> 2) & 1 )); L3=$(( (i >> 3) & 1 ))
    # Right Column (x=1)
    R0=$(( (i >> 4) & 1 )); R1=$(( (i >> 5) & 1 )); R2=$(( (i >> 6) & 1 )); R3=$(( (i >> 7) & 1 ))

    # MAP TO UNICODE BRAILLE DOTS (Visual Alignment)
    # Dot 1:L0(1), Dot 2:L1(2), Dot 3:L2(4), Dot 7:L3(64)
    # Dot 4:R0(8), Dot 5:R1(16), Dot 6:R2(32), Dot 8:R3(128)
    b_val=$(( (L0 << 0) | (L1 << 1) | (L2 << 2) | (R0 << 3) | (R1 << 4) | (R2 << 5) | (L3 << 6) | (R3 << 7) ))
    b_char=$(/usr/bin/printf "\U$(printf "%08x" $((0x2800 + b_val)))")

    # MAP TO LEGACY COMPUTING (Visual Alignment per 1CD57 evidence)
    # Based on the 1CD00 sub-block grid
    l_val=$(( (L0) | (L1 << 1) | (L2 << 2) | (L3 << 3) | (R0 << 4) | (R1 << 5) | (R2 << 6) | (R3 << 7) ))
    l_char=$(/usr/bin/printf "\U$(printf "%08x" $((0x1CD00 + l_val)))")
    l_hex=$(printf "1CD%02X" $l_val)

    printf "%-6d | %-8d | %-8s | %-8s | %-10s\n" "$i" "$i" "$b_char" "$l_char" "$l_hex"
done
