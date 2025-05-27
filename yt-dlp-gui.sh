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
  --text="Enter the YouTube URL and select download quality:" \
  --add-entry="YouTube URL" \
  --add-combo="Quality" \
  --combo-values="360p|480p|720p|1080p|2K|4K|Best|Audio-only (MP3)" \
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

# === Format selector based on quality ===
case "$quality" in
  "360p")   format_code="bestvideo[height<=360]+bestaudio[ext=m4a]" ;;
  "480p")   format_code="bestvideo[height<=480]+bestaudio[ext=m4a]" ;;
  "720p")   format_code="bestvideo[height<=720]+bestaudio[ext=m4a]" ;;
  "1080p")  format_code="bestvideo[height<=1080]+bestaudio[ext=m4a]" ;;
  "2K")     format_code="bestvideo[height<=1440]+bestaudio[ext=m4a]" ;;
  "4K")     format_code="bestvideo[height<=2160]+bestaudio[ext=m4a]" ;;
  "Best")   format_code="bestvideo+bestaudio[ext=m4a]" ;;
  "Audio-only (MP3)") format_code="bestaudio" ;;
  *)        format_code="bestvideo+bestaudio/best" ;;
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
      --merge-output-format mp4 \
      -o "$output_dir/${filename}.%(ext)s" "$url"
  fi
) | zenity --progress --pulsate \
  --title="Downloading..." \
  --text="Please wait..." \
  --no-cancel --auto-close --width=500

# === Check result ===
if [[ $? -eq 0 ]]; then
  zenity --info --text="Download completed and saved in:\n$output_dir"
else
  zenity --error --text="Download failed or was cancelled."
fi
