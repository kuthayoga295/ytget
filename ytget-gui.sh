#!/bin/bash

# Check dependencies
for cmd in yt-dlp ffmpeg yad awk; do
  if ! command -v "$cmd" &>/dev/null; then
    yad --error --text="Missing dependency: '$cmd'" --center --width=400 --height=100
    exit 1
  fi
done

# Show input form
form=$(yad --form --title="YouTube Downloader GUI" --center \
  --width=400 --height=200 \
  --field="YouTube URL" \
  --field="Video Codec Filter:CB" \
  "" "All!avc1 (H.264)!vp9!av01 (AV1)")

[ $? -ne 0 ] && exit 1

url=$(echo "$form" | cut -d'|' -f1)
codec_raw=$(echo "$form" | cut -d'|' -f2)

# Normalize codec
case "$codec_raw" in
  "All") codec_filter="" ;;
  "avc1"*) codec_filter="avc1" ;;
  "vp9") codec_filter="vp9" ;;
  "av01"*) codec_filter="av01" ;;
esac

# Show pulsating progress bar
(
  echo "# Fetching available formats..."
  sleep 1
) | yad --progress --title="Please wait..." \
  --text="Fetching available formats..." \
  --center --width=400 --height=100 \
  --pulsate --auto-close --no-buttons &

# Fetch available formats (safe way)
all_formats=$(yt-dlp -F "$url")
video_formats=$(echo "$all_formats" | grep -E '^[0-9]+.*video')

# Apply codec filter if needed
if [[ -n "$codec_filter" ]]; then
  video_formats=$(echo "$video_formats" | grep -i "$codec_filter")
fi

if [[ -z "$video_formats" ]]; then
  yad --error --text="No video formats found for codec '$codec_filter'." --center --width=400 --height=100
  exit 1
fi

# Build list
list_data=()
while read -r line; do
  code=$(echo "$line" | awk '{print $1}')
  desc=$(echo "$line" | cut -d' ' -f2-)
  list_data+=("$code" "$desc")
done <<< "$video_formats"

list_data+=("audio-mp3" "Audio only (MP3)")

# User select
chosen=$(yad --list --title="Select Format" --center \
  --width=600 --height=400 \
  --column="Format ID" --column="Description" \
  "${list_data[@]}")

[ $? -ne 0 ] && exit 1

format_id=$(echo "$chosen" | awk -F '|' '{print $1}')

# Download process
(
  echo "Downloading, please wait..."
  if [[ "$format_id" == "audio-mp3" ]]; then
    yt-dlp -x --audio-format mp3 -o "$HOME/%(title)s.%(ext)s" "$url"
  else
    is_video_only=$(echo "$all_formats" | awk -v k="$format_id" '$1 == k && $0 ~ /video only/ {print "yes"}')
    if [[ "$is_video_only" == "yes" ]]; then
      yt-dlp -f "$format_id+bestaudio" --merge-output-format mkv \
        --postprocessor-args "ffmpeg:-c:a aac" -o "$HOME/%(title)s.%(ext)s" "$url"
    else
      yt-dlp -f "$format_id" --merge-output-format mkv \
        --postprocessor-args "ffmpeg:-c:a aac" -o "$HOME/%(title)s.%(ext)s" "$url"
    fi
  fi
) | yad --progress \
  --pulsate \
  --no-percentage \
  --title="Downloading..." \
  --text="Please wait..." \
  --center \
  --width=400 \
  --height=100 \
  --auto-close

yad --info --text="Download complete!" --width=400 --height=100 --center
