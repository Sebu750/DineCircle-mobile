#!/usr/bin/env bash
# Optimizes generated PNG masters into web-safe JPEGs inside assets/images.
set -euo pipefail

SRC="$HOME/.qoder/vibe_images"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIN="$ROOT/assets/images/dinners"
RES="$ROOT/assets/images/restaurants"
PPL="$ROOT/assets/images/people"

mkdir -p "$DIN" "$RES" "$PPL"

# dinner scenes -> 1600px wide, quality 80
for pair in \
  "long-table_1791078569.png:long_table" \
  "omakase-counter_1791078568.png:omakase" \
  "rooftop-sunset_1791078566.png:rooftop" \
  "trattoria-pasta_1791078571.png:trattoria" \
  "wine-tasting_1791078572.png:wine_tasting" \
  "fire-feast_1791078605.png:fire_feast" \
  "dessert-tasting_1791078608.png:dessert_tasting" \
  "supper-club_1791078609.png:supper_club" ; do
  src="${pair%%:*}"; name="${pair##*:}"
  convert "$SRC/$src" -resize 1600x -strip -interlace Plane -quality 80 "$DIN/$name.jpg"
done

# restaurant venues -> 1400px wide, quality 80
for pair in \
  "izakaya_1791078602.png:izakaya" \
  "bistro-interior_1791078599.png:bistro" \
  "garden-terrace-restaurant_1791078642.png:garden_terrace" \
  "wine-cellar-restaurant_1791078650.png:wine_cellar" \
  "farm-kitchen_1791078654.png:farm_kitchen" ; do
  src="${pair%%:*}"; name="${pair##*:}"
  convert "$SRC/$src" -resize 1400x -strip -interlace Plane -quality 80 "$RES/$name.jpg"
done

# portraits -> 640x640 square crop, quality 85
for pair in \
  "portrait-chef-ava_1791078645.png:ava" \
  "portrait-sommelier-marco_1791078638.png:marco" \
  "portrait-creator-yuki_1791078654.png:yuki" ; do
  src="${pair%%:*}"; name="${pair##*:}"
  convert "$SRC/$src" -resize 640x640^ -gravity center -extent 640x640 -strip -quality 85 "$PPL/$name.jpg"
done

echo "--- dinners ---";      ls -la "$DIN"
echo "--- restaurants ---";  ls -la "$RES"
echo "--- people ---";       ls -la "$PPL"
du -sh "$ROOT/assets"
