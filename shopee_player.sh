#!/bin/bash
# File: shopee_player.sh
# Description: Script untuk menampilkan Shopee Live dengan MPV player dan mencatat log

# Konfigurasi Dasar
TIMEOUT=10

# Konfigurasi logging
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
LOG_FILE="shopee_player_${TIMESTAMP}.log"

# Fungsi untuk mencatat log
log_message() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Fungsi untuk mencatat error log
log_error() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] ERROR: $message" | tee -a "$LOG_FILE"
}

# Mencatat start script
log_message "====== Script Started ======"
log_message "Log file: $LOG_FILE"

# Cek argumen
if [[ $# -eq 0 ]]; then
  log_error "Short link tidak diberikan sebagai argumen."
  log_message "Penggunaan: $0 <short_link>"
  exit 1
fi

SHORT_LINK="$1"
log_message "Short link: $SHORT_LINK"

# Fungsi untuk mendapatkan ID session dari short link
get_session_id() {
  local short_link="$1"
  log_message "Mencoba mendapatkan session ID dari $short_link"
  
  local location=$(curl -sI "$short_link" | grep -i "Location:" | awk '{print $2}' | tr -d '\r')
  
  if [[ -n "$location" ]]; then
    log_message "Lokasi redirect: $location"
    local session_id=$(echo "$location" | sed -n 's/.*session=\([^&]*\).*/\1/p')
    
    if [[ -n "$session_id" ]]; then
      log_message "Session ID ditemukan: $session_id"
      echo "$session_id"
    else
      log_error "Session ID tidak ditemukan dalam URL redirect"
      echo ""
    fi
  else
    log_error "Tidak mendapatkan header lokasi dari short link"
    echo ""
  fi
}

# Fungsi utama untuk mengambil data livestream dan memutar dengan MPV
fetch_and_play() {
  local session_id=$(get_session_id "$SHORT_LINK")
  
  if [[ -z "$session_id" ]]; then
    log_error "Could not retrieve session ID from the short link."
    return 1
  fi
  
  local url="https://live.shopee.co.id/api/v1/session/$session_id"
  log_message "Mengambil data dari API: $url"
  
  # Fetch data dari API
  local json_data=$(curl -s "$url")
  local err_code=$(echo "$json_data" | jq -r '.err_code')
  
  if [[ "$err_code" -ne 0 ]]; then
    local err_msg=$(echo "$json_data" | jq -r '.err_msg')
    log_error "Error fetching data: $err_msg (error code: $err_code)"
    return 1
  fi
  
  local play_url=$(echo "$json_data" | jq -r '.data.play_urls[0]')
  local title=$(echo "$json_data" | jq -r '.data.session.title')
  
  log_message "Judul: $title"
  log_message "URL Stream: $play_url"
  log_message "Memulai pemutaran dengan MPV..."
  
  # Putar dengan MPV
  # Tambahkan log untuk output MPV
  mpv --autofit=30% "$play_url" 2>&1 | while IFS= read -r line; do
    log_message "MPV: $line"
  done
  
  log_message "Pemutaran selesai"
}

# Validasi dependencies
log_message "Memeriksa dependencies..."

if ! command -v mpv >/dev/null 2>&1; then
  log_error "MPV tidak terinstall. Install dengan: apt install mpv"
  exit 1
else
  log_message "MPV terdeteksi: $(mpv --version | head -n 1)"
fi

if ! command -v jq >/dev/null 2>&1; then
  log_error "jq tidak terinstall. Install dengan: apt install jq"
  exit 1
else
  log_message "jq terdeteksi: $(jq --version)"
fi

if ! command -v curl >/dev/null 2>&1; then
  log_error "curl tidak terinstall. Install dengan: apt install curl"
  exit 1
else
  log_message "curl terdeteksi: $(curl --version | head -n 1)"
fi

# Jalankan script
log_message "Dependencies OK, menjalankan fungsi utama..."
fetch_and_play

# Mencatat akhir script
log_message "====== Script Selesai ======"
