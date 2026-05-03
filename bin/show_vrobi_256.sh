#!/usr/bin/env bash
set -u

cfg="${1:-1}"

cd ~/dev/newbashplot/bin
. ./setup.sh "$cfg"

printf 'VROBI config: %s\n' "$nbp_virtualBitmap"
printf 'Each cell shows: decimal bitmask, hex bitmask, glyph\n\n'

for row in {0..15}; do
  for col in {0..15}; do
    idx=$((row * 16 + col))
    printf '%3d/%02X:%s ' "$idx" "$idx" "${nbp_VROBI[$idx]}"
  done
  printf '\n'
done

printf '\nFull-block repeat test, bitmask 255:\n'
for r in {1..6}; do
  for c in {1..80}; do
    printf '%s' "${nbp_VROBI[255]}"
  done
  printf '\n'
done

printf '\nNative U+2588 repeat control:\n'
for r in {1..6}; do
  printf '████████████████████████████████████████████████████████████████████████████████\n'
done
