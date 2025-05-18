#!/bin/bash

OUTDIR="$HOME/Downloads"

# Check dependencies
command -v yt-dlp >/dev/null 2>&1 || {
    echo "[ERROR] yt-dlp not found."
    echo "Download from: https://github.com/yt-dlp/yt-dlp"
    read -rp "Press Enter to exit..."
    exit 1
}

command -v mpv >/dev/null 2>&1 || {
    echo "[ERROR] mpv player not found."
    echo "Download from: https://mpv.io/installation/"
    read -rp "Press Enter to exit..."
    exit 1
}

command -v ffmpeg >/dev/null 2>&1 || {
    echo "[ERROR] FFmpeg not found."
    echo "Required for audio conversion and video merging."
    echo "Download from: https://ffmpeg.org/download.html"
    read -rp "Press Enter to exit..."
    exit 1
}

function menu() {
    clear
    echo "=============================="
    echo "      YOUTUBE DOWNLOADER"
    echo "=============================="
    read -rp "Enter YouTube URL: " URL

    if [[ -z "$URL" ]]; then
        echo "[ERROR] URL cannot be empty."
        read -rp "Press Enter to continue..."
        menu
        return
    fi

    echo "[1] Download Video (Best Quality)"
    echo "[2] Download Audio (MP3)"
    echo "[3] Select Video Format"
    echo "[4] Stream Video"
    echo "[0] Exit"
    echo "=============================="
    read -rp "Enter choice [0-4]: " CHOICE

    case "$CHOICE" in
        1) best_video ;;
        2) audio ;;
        3) select_format ;;
        4) play ;;
        0) exit 0 ;;
        *) echo "Invalid choice!"; read -rp "Press Enter to continue..."; menu ;;
    esac
}

function best_video() {
    clear
    echo "Downloading best quality video..."
    yt-dlp -f "bestvideo+bestaudio" --merge-output-format mkv -o "${OUTDIR}/%(title)s.%(ext)s" "$URL"
    read -rp "Press Enter to continue..."
    menu
}

function audio() {
    clear
    echo "Downloading best audio as MP3..."
    yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 -o "${OUTDIR}/%(title)s.%(ext)s" "$URL"
    read -rp "Press Enter to continue..."
    menu
}

function select_format() {
    clear
    echo "Available formats:"
    yt-dlp -F "$URL"
    echo
    read -rp "Enter format code (e.g., 136): " FORMAT

    if [[ -z "$FORMAT" ]]; then
        echo "[ERROR] Format code required."
        read -rp "Press Enter to continue..."
        select_format
        return
    fi

    echo "Downloading format $FORMAT + bestaudio..."
    yt-dlp -f "$FORMAT+bestaudio" --merge-output-format mkv -o "${OUTDIR}/%(title)s.%(ext)s" "$URL"
    read -rp "Press Enter to continue..."
    menu
}

function play() {
    clear
    echo "==============================="
    echo "        STREAM OPTIONS"
    echo "==============================="
    echo "[1] Best Quality (Auto)"
    echo "[2] 1080p"
    echo "[3] 720p"
    echo "[4] 480p"
    echo "[5] 360p"
    echo "[0] Back to Main Menu"
    echo "==============================="
    read -rp "Select quality [0-5]: " RES

    MPV_FLAGS="--hwdec=auto-safe"

    case "$RES" in
        1) echo "Streaming best quality..."; mpv $MPV_FLAGS "$URL" ;;
        2) echo "Streaming 1080p..."; mpv $MPV_FLAGS --ytdl-format="bestvideo[height<=1080]+bestaudio/best[height<=1080]" "$URL" ;;
        3) echo "Streaming 720p..."; mpv $MPV_FLAGS --ytdl-format="bestvideo[height<=720]+bestaudio/best[height<=720]" "$URL" ;;
        4) echo "Streaming 480p..."; mpv $MPV_FLAGS --ytdl-format="bestvideo[height<=480]+bestaudio/best[height<=480]" "$URL" ;;
        5) echo "Streaming 360p..."; mpv $MPV_FLAGS --ytdl-format="bestvideo[height<=360]+bestaudio/best[height<=360]" "$URL" ;;
        0) menu; return ;;
        *) echo "Invalid choice!"; read -rp "Press Enter to continue..."; play; return ;;
    esac

    read -rp "Press Enter to continue..."
    play
}

menu
