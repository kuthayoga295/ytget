#!/bin/bash

# === Check dependencies ===
for cmd in yt-dlp ffmpeg zenity awk; do
  if ! command -v "$cmd" &>/dev/null; then
    zenity --error --title="Missing Dependency" \
      --text="Required command '$cmd' not found!" \
      --width=400 --height=100
    exit 1
  fi
done

# === Input URL and codec ===
input=$(zenity --forms --title="YouTube Downloader" \
  --text="Enter the YouTube URL and select video codec:" \
  --add-entry="YouTube URL" \
  --add-combo="Video Codec" \
  --combo-values="all|avc1|vp9|av01" \
  --width=500 --height=200)

[ -z "$input" ] && exit 1

url=$(echo "$input" | awk -F'|' '{print $1}')
codec_choice=$(echo "$input" | awk -F'|' '{print $2}')
[[ "$codec_choice" == "all" ]] && codec_filter="" || codec_filter="$codec_choice"

# === Fetch available formats ===
mapfile -t formats < <(yt-dlp -F "$url" | grep -E '^[0-9]+.*video' | grep -i "$codec_filter")
if [[ ${#formats[@]} -eq 0 ]]; then
  zenity --error --title="No Formats Found" \
    --text="No video formats found with codec '$codec_choice'." \
    --width=400 --height=100
  exit 1
fi

# === Build Zenity list ===
zenity_list=()
for line in "${formats[@]}"; do
  fid=$(echo "$line" | awk '{print $1}')
  desc=$(echo "$line" | cut -d' ' -f2-)
  zenity_list+=("$fid" "$desc")
done
zenity_list+=("audio-mp3" "Audio only (MP3)")

# === Choose format ===
chosen=$(zenity --list --title="Select Video Format" \
  --column="Format ID" --column="Description" \
  "${zenity_list[@]}" \
  --width=800 --height=400)

[ -z "$chosen" ] && exit 1

# === Temporary log file ===
logfile=$(mktemp)

# === Start download and log output ===
{
  echo "Downloading: $url"
  echo "Selected Format: $chosen"
  echo "Codec Filter: ${codec_choice}"
  echo "----------------------------------------"

  if [[ "$chosen" == "audio-mp3" ]]; then
    yt-dlp -x --audio-format mp3 -o "$HOME/%(title)s.%(ext)s" "$url"
  else
    is_video_only=$(yt-dlp -F "$url" | awk -v k="$chosen" '$1 == k && $0 ~ /video only/ { print "yes" }')
    if [[ "$is_video_only" == "yes" ]]; then
      yt-dlp -f "$chosen+bestaudio" --merge-output-format mkv --postprocessor-args "ffmpeg:-c:a aac" -o "$HOME/%(title)s.%(ext)s" "$url"
    else
      yt-dlp -f "$chosen" --merge-output-format mkv --postprocessor-args "ffmpeg:-c:a aac" -o "$HOME/%(title)s.%(ext)s" "$url"
    fi
  fi

  echo ""
  echo "Download completed."
} &> "$logfile" &

# === Show terminal-style progress ===
(
  tail -f "$logfile" &
  tail_pid=$!
  wait $!
  kill $tail_pid
) | zenity --text-info \
    --title="Download Progress" \
    --width=800 --height=500 \
    --ok-label="Close"

# === Cleanup ===
rm -f "$logfile"
