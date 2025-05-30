#!/bin/bash

# === Check dependencies ===
for cmd in yt-dlp ffmpeg zenity awk; do
  if ! command -v "$cmd" &>/dev/null; then
    zenity --error --title="Missing Dependency" \
      --text="Command '$cmd' not found. Please install it first."
    exit 1
  fi
done

# === Input URL and quality ===
input=$(zenity --forms --title="YouTube Downloader" \
  --text="Enter URL and select download quality: " \
  --add-entry="YouTube URL" \
  --add-combo="Quality" \
  --combo-values="Best|360p|480p|720p|1080p|2K|4K|Audio-only" \
  --width=500 --height=200)

# === Handle cancel ===
if [[ $? -ne 0 ]]; then
  exit 0
fi

# === Parse input ===
url=$(echo "$input" | awk -F'|' '{print $1}' | xargs)
quality=$(echo "$input" | awk -F'|' '{print $2}' | xargs)

if [[ -z "$url" || -z "$quality" ]]; then
  zenity --error --text="URL or quality selection must not be empty."
  exit 1
fi

if ! [[ "$url" =~ ^https?://(www\.)?(youtube\.com|youtu\.be|music\.youtube\.com)/ ]]; then
  zenity --error --text="Invalid YouTube or YouTube Music URL."
  exit 1
fi

# === Format selector based on quality ===
case "$quality" in
  "360p")   format_code="bv[height<=360][vcodec^=avc]+ba[acodec^=mp4a]/bv[height<=360]+ba --merge-output-format mp4 " ;;
  "480p")   format_code="bv[height<=480][vcodec^=avc]+ba[acodec^=mp4a]/bv[height<=480]+ba --merge-output-format mp4 " ;;
  "720p")   format_code="bv[height<=720][vcodec^=avc]+ba[acodec^=mp4a]/bv[height<=720]+ba --merge-output-format mp4 " ;;
  "1080p")  format_code="bv[height<=1080][vcodec^=avc]+ba[acodec^=mp4a]/bv[height<=1080]+ba --merge-output-format mp4 " ;;
  "2K")     format_code="bv[height<=1440]+ba --merge-output-format mkv " ;;
  "4K")     format_code="bv[height<=2160]+ba --merge-output-format mkv " ;;
  "Best")   format_code="bv+ba --merge-output-format mkv " ;;
  "Audio-only") format_code="ba[acodec^=mp4a]" ;;
  *)        format_code="bv+ba --merge-output-format mkv " ;;
esac

# === Output directory ===
output_dir="$HOME/Downloads"

# === Get safe video title for filename ===
title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "video_$(date +%s)")
filename=$(echo "$title" | tr -dc '[:alnum:]\n\r _-' | tr ' ' '_')

# === Download with simple progress ===
(
  if [[ "$quality" == "Audio-only (MP3)" ]]; then
    yt-dlp -x --audio-format mp3 --audio-quality 0 \
      -o "$output_dir/${filename}.%(ext)s" "$url"
  else
    yt-dlp -f "$format_code" \
      -o "$output_dir/${filename}.%(ext)s" "$url"
  fi
) | zenity --progress --pulsate \
  --title="Downloading..." \
  --text="Please wait..." \
  --no-cancel --auto-close --width=400

# === Check result ===
if [[ $? -eq 0 ]]; then
  zenity --info --text="Download completed and saved in:\n$output_dir"
else
  zenity --error --text="Download failed or was cancelled."
fi
