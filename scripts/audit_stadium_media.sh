#!/usr/bin/env bash
# Inspecte les deux vidéos du stade + le poster, sans altérer les fichiers.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v ffmpeg >/dev/null || { echo "ffmpeg absent" >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "ffprobe absent" >&2; exit 1; }
out="${1:-build/stadium-media-audit}"
mkdir -p "$out"
report="$out/report.md"
printf '# Contrôle vidéo du stade — Petit Filet\n\n' > "$report"
printf 'Sources : fichiers locaux du dépôt (aucune donnée utilisateur).\n\n' >> "$report"

for file in assets/composition/stade.mp4 assets/composition/stade-720.mp4; do
  test -s "$file" || { echo "Fichier manquant : $file" >&2; exit 1; }
  name="$(basename "$file" .mp4)"
  duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")"
  specs="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,codec_name,r_frame_rate -of csv=p=0 "$file")"
  printf '## %s\n\n- Vidéo : `%s`\n- Durée (s) : %s\n- Flux vidéo : %s\n\n' "$name" "$file" "$duration" "$specs" >> "$report"
  # Cinq images réparties dans la durée pour détecter un lettrage animé.
  for index in 0 1 2 3 4; do
    timestamp="$(awk -v d="$duration" -v n="$index" 'BEGIN {printf "%.3f", d*(n/5.0)}')"
    image="$out/$name-$index.jpg"
    ffmpeg -hide_banner -loglevel error -y -ss "$timestamp" -i "$file" \
      -frames:v 1 -vf 'scale=720:-2' "$image"
    printf -- '- Image %s : `%s`\n' "$timestamp" "$image" >> "$report"
  done
  # Contact sheet compacte, utile pour comparer les deux encodages.
  ffmpeg -hide_banner -loglevel error -y \
    -framerate 1 -pattern_type glob -i "$out/$name-*.jpg" \
    -frames:v 1 -vf 'tile=5x1' "$out/$name-planche.jpg"
  printf '\n' >> "$report"
done

test -s assets/composition/stade.jpg || { echo 'Poster manquant' >&2; exit 1; }
cp assets/composition/stade.jpg "$out/stade-poster.jpg"
printf '## Poster\n\n- `stade-poster.jpg` : image à vérifier indépendamment des vidéos.\n\n' >> "$report"
sha256sum assets/composition/stade.mp4 assets/composition/stade-720.mp4 \
  assets/composition/stade.jpg > "$out/sha256.txt"
printf 'À valider visuellement : **zéro inscription AS Grinta** sur tribunes,\n' >> "$report"
printf 'drapeaux, public et poster ; aucun logo de remplacement.\n' >> "$report"
echo "Contrôle préparé dans : $out"
