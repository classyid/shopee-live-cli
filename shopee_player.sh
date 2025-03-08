#!/bin/bash
# File: shopee_player.sh
# Description: Script untuk menampilkan Shopee Live dengan MPV player

# Konfigurasi Dasar
TIMEOUT=10

# Cek argumen
if [[ $# -eq 0 ]]; then
  echo "Error: Short link tidak diberikan sebagai argumen."
  echo "Penggunaan: $0 <short_link>"
  exit 1
fi

SHORT_LINK="$1"

# Fungsi untuk mendapatkan ID session dari short link
get_session_id() {
  local short_link="$1"
  local location=$(curl -sI "$short_link" | grep -i "Location:" | awk '{print $2}' | tr -d '\r')
  
  if [[ -n "$location" ]]; then
    local session_id=$(echo "$location" | sed -n 's/.*session=\([^&]*\).*/\1/p')
    echo "$session_id"
  else
    echo ""
  fi
}

# Fungsi utama untuk mengambil data livestream dan memutar dengan MPV
fetch_and_play() {
  local session_id=$(get_session_id "$SHORT_LINK")
  
  if [[ -z "$session_id" ]]; then
    echo "Error: Could not retrieve session ID from the short link."
    return 1
  fi
  
  local url="https://live.shopee.co.id/api/v1/session/$session_id"
  
  # Fetch data dari API
  local json_data=$(curl -s "$url")
  local err_code=$(echo "$json_data" | jq -r '.err_code')
  
  if [[ "$err_code" -ne 0 ]]; then
    local err_msg=$(echo "$json_data" | jq -r '.err_msg')
    echo "Error fetching data: $err_msg"
    return 1
  fi
  
  local play_url=$(echo "$json_data" | jq -r '.data.play_urls[0]')
  local title=$(echo "$json_data" | jq -r '.data.session.title')
  
  echo "Judul: $title"
  echo "URL Stream: $play_url"
  echo "Memulai pemutaran dengan MPV..."
  
  # Putar dengan MPV
  # Sesuaikan parameter sesuai kebutuhan
  mpv --autofit=30% "$play_url"
}

# Validasi dependencies
command -v mpv >/dev/null 2>&1 || { echo "MPV tidak terinstall. Install dengan: apt install mpv"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq tidak terinstall. Install dengan: apt install jq"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl tidak terinstall. Install dengan: apt install curl"; exit 1; }

# Jalankan script
fetch_and_play
