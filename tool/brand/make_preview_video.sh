#!/usr/bin/env bash
# Dựng video giới thiệu (không âm thanh) từ các khung trong store/video/frames/.
#   bash tool/brand/make_preview_video.sh
# Cần ffmpeg. Đầu ra:
#   store/video/app_preview_1080x1920.mp4  (Google Play / YouTube / web)
#   store/video/app_preview_886x1920.mp4   (App Store Connect — App Preview 6.5"/6.7")
set -euo pipefail
cd "$(dirname "$0")/../.."
FR=store/video/frames
OUT=store/video
FADE=0.6
mapfile -t FILES < <(ls "$FR"/*.png | sort)
N=${#FILES[@]}
inputs=()
for i in "${!FILES[@]}"; do
  d=3.4
  if [ "$i" -eq 0 ] || [ "$i" -eq $((N-1)) ]; then d=2.6; fi
  inputs+=(-loop 1 -t "$d" -i "${FILES[$i]}")
done
# xfade nối tiếp: offset = tổng thời lượng trước đó - (số mối nối * FADE)
filter=""
prev="[0:v]"
acc=2.6
for ((i=1; i<N; i++)); do
  off=$(awk -v a="$acc" -v f="$FADE" 'BEGIN{printf "%.2f", a - f}')
  tag="[x$i]"
  filter+="${prev}[$i:v]xfade=transition=fade:duration=$FADE:offset=$off${tag};"
  prev="$tag"
  d=3.4
  if [ "$i" -eq $((N-1)) ]; then d=2.6; fi
  acc=$(awk -v a="$acc" -v d="$d" -v f="$FADE" 'BEGIN{printf "%.2f", a + d - f}')
done
filter+="${prev}format=yuv420p,fps=30[v]"
ffmpeg -y -loglevel error "${inputs[@]}" -filter_complex "$filter" -map "[v]" \
  -c:v libx264 -preset slow -crf 18 -movflags +faststart "$OUT/app_preview_1080x1920.mp4"
ffmpeg -y -loglevel error -i "$OUT/app_preview_1080x1920.mp4" \
  -vf "scale=-2:1920,crop=886:1920" -c:v libx264 -preset slow -crf 18 \
  -movflags +faststart "$OUT/app_preview_886x1920.mp4"
ls -la "$OUT"/*.mp4
