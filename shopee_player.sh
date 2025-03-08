#!/bin/bash
# File: shopee_player.sh
# Description: Script untuk menampilkan Shopee Live dengan MPV player
# Dengan fitur logging berdasarkan tanggal dan waktu

# Konfigurasi Dasar
TIMEOUT=10

# Konfigurasi log
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/shopee_player_${TIMESTAMP}.log"

# Fungsi logger
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log "====== Script Started ======"
log "Log file created at: $LOG_FILE"

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
  log "Mendapatkan session ID dari: $short_link"
  
  local location=$(curl -sI "$short_link" | grep -i "Location:" | awk '{print $2}' | tr -d '\r')
  
  if [[ -n "$location" ]]; then
    log "Redirect URL: $location"
    local session_id=$(echo "$location" | sed -n 's/.*session=\([^&]*\).*/\1/p')
    log "Session ID: $session_id"
    echo "$session_id"
  else
    log "Error: Tidak mendapatkan URL redirect"
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
  log "Mengambil data dari API..."
  local json_data=$(curl -s "$url")
  
  # Simpan respons untuk debugging
  echo "$json_data" > "$LOG_DIR/api_response_${TIMESTAMP}.json"
  log "Respons API disimpan ke $LOG_DIR/api_response_${TIMESTAMP}.json"
  
  # Gunakan -e untuk menghindari masalah jika err_code tidak ada
  local err_code=$(echo "$json_data" | jq -e '.err_code' 2>/dev/null)
  
  # Perhatikan operator bash yang benar: -ne untuk numerik
  if [[ -n "$err_code" && "$err_code" -ne 0 ]]; then
    local err_msg=$(echo "$json_data" | jq -r '.err_msg')
    log "Error fetching data: $err_msg"
    return 1
  fi
  
  local play_url=$(echo "$json_data" | jq -r '.data.play_urls[0]')
  local title=$(echo "$json_data" | jq -r '.data.session.title')
  
  log "Judul: $title"
  log "URL Stream: $play_url"
  
  if [[ -z "$play_url" ]]; then
    log "Error: Stream URL kosong, tidak bisa memutar stream"
    return 1
  fi
  
  log "Memulai pemutaran dengan MPV..."
  
  # Putar dengan MPV
  # Sesuaikan parameter sesuai kebutuhan
  mpv --autofit=30% "$play_url" 2>&1 | while read -r line; do
    log "MPV: $line"
  done
  
  log "Pemutaran selesai"
}

# Validasi dependencies
log "Memeriksa dependencies..."

if ! command -v mpv >/dev/null 2>&1; then
  log "Error: MPV tidak terinstall. Install dengan: apt install mpv"
  exit 1
else
  log "MPV terinstall: $(mpv --version | head -n 1)"
fi

if ! command -v jq >/dev/null 2>&1; then
  log "Error: jq tidak terinstall. Install dengan: apt install jq"
  exit 1
else
  log "jq terinstall: $(jq --version)"
fi

if ! command -v curl >/dev/null 2>&1; then
  log "Error: curl tidak terinstall. Install dengan: apt install curl"
  exit 1
else
  log "curl terinstall: $(curl --version | head -n 1)"
fi

# Jalankan script
log "Semua dependency terpenuhi, menjalankan fetch_and_play..."
fetch_and_play
log "====== Script Selesai ======"
