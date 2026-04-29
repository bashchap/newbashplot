#!/bin/bash

# Unicode Braille Dot Weights:
# Dot1:1, Dot2:2, Dot3:4, Dot4:8, Dot5:16, Dot6:32, Dot7:64, Dot8:128
#
# Your Bitmask Logic (2^y << x*4):
# Left Col (x=0): Bits 0,1,2,3 -> Should map to Dots 1,2,3,7
# Right Col (x=1): Bits 4,5,6,7 -> Should map to Dots 4,5,6,8

printf "%-6s | %-8s | %-8s | %-8s | %-10s\n" "Index" "Bitmask" "Braille" "Legacy" "Legacy Hex"
echo "------------------------------------------------------------"

for i in {0..255}; do
    # Extract your 8 bits
    L0=$(( (i >> 0) & 1 )); L1=$(( (i >> 1) & 1 )); L2=$(( (i >> 2) & 1 )); L3=$(( (i >> 3) & 1 ))
    R0=$(( (i >> 4) & 1 )); R1=$(( (i >> 5) & 1 )); R2=$(( (i >> 6) & 1 )); R3=$(( (i >> 7) & 1 ))

    # 1. Manually construct Braille Offset to MATCH your visual bits
    # Dot1(1)=L0, Dot2(2)=L1, Dot3(4)=L2, Dot7(64)=L3
    # Dot4(8)=R0, Dot5(16)=R1, Dot6(32)=R2, Dot8(128)=R3
    b_off=$(( (L0 << 0) | (L1 << 1) | (L2 << 2) | (R0 << 3) | (R1 << 4) | (R2 << 5) | (L3 << 6) | (R3 << 7) ))
    b_char=$(/usr/bin/printf "\U$(printf "%08x" $((0x2800 + b_off)))")

    # 2. Map to Legacy Block based on your confirmed 1CD57 Checkerboard (Index 165)
    # Your evidence: Index 165 (L0, L2, R1, R3) = 1CD57
    # This suggests a specific bit-shuffling in the 1CDxx sub-range.
    # We map your L-bits to the low nibble and R-bits to the high nibble:
    l_hex_val=$(( (L0) | (L1 << 1) | (L2 << 2) | (L3 << 3) | (R0 << 4) | (R1 << 5) | (R2 << 6) | (R3 << 7) ))
    
    # Using 1CD00 as the base for the octant sub-block
    l_char=$(/usr/bin/printf "\U$(printf "%08x" $((0x1CD00 + l_hex_val)))")
    l_addr=$(printf "1CD%02X" $l_hex_val)

    printf "%-6d | %-8d | %-8s | %-8s | %-10s\n" "$i" "$i" "$b_char" "$l_char" "$l_addr"
done
