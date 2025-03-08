#!/bin/bash
# File: shopee_player.sh
# Description: Script untuk menampilkan Shopee Live dengan MPV player
# Konfigurasi Dasar
TIMEOUT=10

# Buat file log dengan timestamp
LOG_FILE="shopee_player_$(date +%Y-%m-%d_%H-%M-%S).log"

# Fungsi untuk mencatat ke log dan juga menampilkan di terminal
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") $*" | tee -a "$LOG_FILE"
}

# Cek argumen
if [[ $# -eq 0 ]]; then
  log "Error: Short link tidak diberikan sebagai argumen."
  log "Penggunaan: $0 <short_link>"
  exit 1
fi

SHORT_LINK="$1"
log "Short link: $SHORT_LINK"

# Fungsi untuk mendapatkan ID session dari short link
get_session_id() {
  local short_link="$1"
  local location=$(curl -sI "$short_link" | grep -i "Location:" | awk '{print $2}' | tr -d '\r')
  
  if [[ -n "$location" ]]; then
    log "Location: $location"
    local session_id=$(echo "$location" | sed -n 's/.*session=\([^&]*\).*/\1/p')
    log "Session ID: $session_id"
    echo "$session_id"
  else
    log "Error: Tidak dapat menemukan location header"
    echo ""
  fi
}

# Fungsi utama untuk mengambil data livestream dan memutar dengan MPV
fetch_and_play() {
  local session_id=$(get_session_id "$SHORT_LINK")
  
  if [[ -z "$session_id" ]]; then
    log "Error: Could not retrieve session ID from the short link."
    return 1
  fi
  
  local url="https://live.shopee.co.id/api/v1/session/$session_id"
  log "API URL: $url"
  
  # Fetch data dari API
  local json_data=$(curl -s "$url")
  local err_code=$(echo "$json_data" | jq -r '.err_code')
  
  if [[ "$err_code" -ne 0 ]]; then
    local err_msg=$(echo "$json_data" | jq -r '.err_msg')
    log "Error fetching data: $err_msg"
    return 1
  fi
  
  local play_url=$(echo "$json_data" | jq -r '.data.play_urls[0]')
  local title=$(echo "$json_data" | jq -r '.data.session.title')
  
  log "Judul: $title"
  log "URL Stream: $play_url"
  log "Memulai pemutaran dengan MPV..."
  
  # Putar dengan MPV
  # Sesuaikan parameter sesuai kebutuhan
  mpv --autofit=30% "$play_url"
  
  log "Pemutaran selesai"
}

# Validasi dependencies
command -v mpv >/dev/null 2>&1 || { log "MPV tidak terinstall. Install dengan: apt install mpv"; exit 1; }
command -v jq >/dev/null 2>&1 || { log "jq tidak terinstall. Install dengan: apt install jq"; exit 1; }
command -v curl >/dev/null 2>&1 || { log "curl tidak terinstall. Install dengan: apt install curl"; exit 1; }

# Jalankan script
log "Menjalankan fetch_and_play..."
fetch_and_play
log "Script selesai"
