#!/bin/bash
clear
echo "=== YouTube Downloader ==="
echo ""

# === Cek dependensi ===
echo "Mengecek dependensi..."

for cmd in yt-dlp ffmpeg awk; do
  if ! command -v $cmd &>/dev/null; then
    echo "Dependensi '$cmd' tidak ditemukan! Silakan install yt-dlp dan ffmpeg terlebih dahulu."
    exit 1
  fi
done

echo "Semua dependensi terpenuhi."
echo ""

# === Input URL ===
read -p "Masukkan URL YouTube: " url
echo ""

# === Pilih codec ===
echo "Filter codec video:"
echo "1) Semua codec"
echo "2) H.264 / AVC (avc1)"
echo "3) VP9 (vp9)"
echo "4) AV1 (av01)"
read -p "Pilih filter codec [1-4]: " codec_choice

case $codec_choice in
  1) codec_filter="" ;;
  2) codec_filter="avc1" ;;
  3) codec_filter="vp" ;;
  4) codec_filter="av01" ;;
  *) echo "Pilihan tidak valid!"; exit 1 ;;
esac

echo ""
echo "Mengambil daftar format dari YouTube..."

# === Ambil format berdasarkan codec ===
mapfile -t formats < <(yt-dlp -F "$url" | grep -E '^[0-9]+.*(video)' | grep -i "$codec_filter")

if [[ ${#formats[@]} -eq 0 ]]; then
  echo "Tidak ada format video dengan codec '$codec_filter'."
  exit 1
fi

# === Tampilkan format ===
echo ""
echo "=== Format Video yang tersedia '${codec_filter:-Semua}' ==="
i=1
declare -A format_codes

for line in "${formats[@]}"; do
  format_code=$(echo "$line" | awk '{print $1}')
  info=$(echo "$line" | cut -d' ' -f2-)
  echo "$i) $info"
  format_codes[$i]=$format_code
  ((i++))
done

# Tambahkan opsi audio-only
echo "$i) Audio only (MP3)"
audio_option=$i

echo ""
read -p "Pilih nomor yang ingin diunduh [1-$i]: " pilihan
echo ""

# === Audio Only ===
if [[ "$pilihan" -eq "$audio_option" ]]; then
  echo "Mengunduh audio-only (MP3)..."
  yt-dlp -x --audio-format mp3 -o "$HOME/%(title)s.%(ext)s" "$url"

# === Video / Audio Merge ===
elif [[ "${format_codes[$pilihan]}" ]]; then
  kode="${format_codes[$pilihan]}"

  # Cek apakah video-only
  is_video_only=$(yt-dlp -F "$url" | awk -v k="$kode" '$1 == k && $0 ~ /video only/ { print "yes" }')

  if [[ "$is_video_only" == "yes" ]]; then
    echo "Format ini video-only, menggabungkan dengan best audio..."
    yt-dlp -f "$kode+bestaudio" --merge-output-format mkv --postprocessor-args "ffmpeg:-c:a aac" -o "$HOME/%(title)s.%(ext)s" "$url"
  else
    echo "Format ini sudah termasuk audio, langsung unduh..."
    yt-dlp -f "$kode" --merge-output-format mkv --postprocessor-args "ffmpeg:-c:a aac" -o "$HOME/%(title)s.%(ext)s" "$url"
  fi

else
  echo "Pilihan tidak valid!"
  exit 1
fi
