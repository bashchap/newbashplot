#!/bin/bash
# Configuration for the Legacy Octant Block
START=1ce00
END=1ceff
FILE="UnicodeCodePoint-x1CE00-x100-x1CEFF.cfg"

echo "# Unicode Mapping for Legacy Computing Octants (U+1CE00 - U+1CEFF)" > "$FILE"
echo "# Format: uCodePoint_LEGACY[offset]=\"Actual_Character\"" >> "$FILE"

for ((i=16#$START; i<=16#$END; i++)); do
    # Calculate relative offset from the start of the block
    offset=$((i - 16#$START))
    
    # Generate the 8-digit hex for the \U escape
    hex_val=$(printf "%08x" $i)
    
    # Generate the character using the system printf
    char=$(/usr/bin/printf "\U$hex_val")
    
    # Write to file
    echo "uCodePoint_LEGACY[$offset]=\"$char\"" >> "$FILE"
done

echo "Successfully generated $FILE"
