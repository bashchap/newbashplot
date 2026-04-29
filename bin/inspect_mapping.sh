#!/bin/bash

# Configuration
BRAILLE_START=0x2800
LEGACY_BLOCK_START=0x1CD00
# Note: 1CD57 is our confirmed checkerboard (Index 165)
# In Braille, Index 165 is 0x2800 + 165 = 0x28A5? No.
# Braille bit ordering is different. We will use your 2x4 bitmask logic.

printf "%-10s | %-10s | %-10s | %-10s | %-10s\n" "Index" "Bitmask" "Braille" "Legacy" "Legacy Hex"
echo "--------------------------------------------------------------------------"

for i in {0..255}; do
    # 1. Calculate bits based on your formula (2^y) << (x*4)
    # Left Column (x=0): 1, 2, 4, 8
    # Right Column (x=1): 16, 32, 64, 128
    
    # 2. Map these to the standard Braille Dot Pattern (for visual comparison)
    # Braille Dots: 1(1), 2(2), 3(4), 4(16), 5(32), 6(64), 7(8), 8(128)
    L0=$(( (i >> 0) & 1 )); L1=$(( (i >> 1) & 1 )); L2=$(( (i >> 2) & 1 )); L3=$(( (i >> 3) & 1 ))
    R0=$(( (i >> 4) & 1 )); R1=$(( (i >> 5) & 1 )); R2=$(( (i >> 6) & 1 )); R3=$(( (i >> 7) & 1 ))
    
    # Braille Offset calculation
    b_off=$(( (L0 << 0) | (L1 << 1) | (L2 << 2) | (R0 << 3) | (R1 << 4) | (R2 << 5) | (L3 << 6) | (R3 << 7) ))
    b_char=$(/usr/bin/printf "\U$(printf "%08x" $((BRAILLE_START + b_off)))")
    
    # 3. Map to Legacy Block based on our confirmed 1CD57 evidence
    # Your evidence: Index 165 (Checkerboard) maps to 1CD57
    # 1CD57 is offset 0x57 (87) from 1CD00. 
    # Logic: Offset = (L0*1 + L1*2 + L2*4 + L3*8) + (R0*16 + R1*32 + R2*64 + R3*128) 
    # Actually, in this block, the hex digits often correspond to the columns.
    
    l_hex=$(( (L0 + L1*2 + L2*4 + L3*8) + (R0*16 + R1*32 + R2*64 + R3*128) ))
    l_char=$(/usr/bin/printf "\U$(printf "%08x" $((LEGACY_BLOCK_START + l_hex)))")
    
    # Print the row
    printf "%-10d | %-10d | %-10s | %-10s | %-10s\n" "$i" "$i" "$b_char" "$l_char" "$(printf "1CD%02X" $l_hex)"
done
