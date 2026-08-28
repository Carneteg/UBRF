#!/usr/bin/env bash
# Konverterar HEIC-foton (iPhone) till JPG som Claude Code kan öppna med Read.
# Användning:
#   tools/convert-photos.sh <mapp-med-HEIC> <byggnad> <fasad>
#   ex: tools/convert-photos.sh ~/Downloads/UBRF ridhus syd
# Resultat: references/buildings/ridhus/ridhus-syd-01.jpg, -02.jpg ...
# Bilderna skalas till max 2000 px på långsidan (räcker gott, sparar tokens).
set -euo pipefail

SRC="${1:?ange mapp med HEIC}"
BYGGNAD="${2:?ange byggnad, t.ex. ridhus}"
FASAD="${3:-blandat}"
OUT="references/buildings/$BYGGNAD"
mkdir -p "$OUT"

n=$(ls "$OUT"/"$BYGGNAD-$FASAD"-*.jpg 2>/dev/null | wc -l | tr -d ' ')
for f in "$SRC"/*.HEIC "$SRC"/*.heic "$SRC"/*.jpg "$SRC"/*.JPG "$SRC"/*.png; do
  [ -e "$f" ] || continue
  n=$((n+1))
  dest="$OUT/$(printf '%s-%s-%02d.jpg' "$BYGGNAD" "$FASAD" "$n")"
  if command -v sips >/dev/null 2>&1; then                # macOS
    sips -s format jpeg -Z 2000 "$f" --out "$dest" >/dev/null
  elif command -v magick >/dev/null 2>&1; then            # ImageMagick 7 (Windows/Linux)
    magick "$f" -auto-orient -resize 2000x2000\> -quality 88 "$dest"
  elif command -v heif-convert >/dev/null 2>&1; then      # libheif
    heif-convert "$f" "$dest" >/dev/null
  else
    echo "Hittar inget konverteringsverktyg. macOS: sips finns inbyggt. Windows: installera ImageMagick (winget install ImageMagick.ImageMagick)." >&2
    exit 1
  fi
  echo "→ $dest"
done
echo "Klart. Kör nu: /fotoanalys $BYGGNAD"
