#!/bin/bash
# File: shopee_player.sh
# Description: Script untuk menampilkan Shopee Live dengan MPV player

# Konfigurasi Dasar
TIMEOUT=10
LOG_FILE="shopee_player_$(date +%Y%m%d_%H%M%S).log"

# Fungsi Logging
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log "INFO" "Script dimulai"
log "INFO" "File log dibuat: $LOG_FILE"

# Cek argumen
if [[ $# -eq 0 ]]; then
  log "ERROR" "Short link tidak diberikan sebagai argumen."
  log "INFO" "Penggunaan: $0 <short_link>"
  echo "Error: Short link tidak diberikan sebagai argumen."
  echo "Penggunaan: $0 <short_link>"
  exit 1
fi

SHORT_LINK="$1"
log "INFO" "Short link diterima: $SHORT_LINK"

# Fungsi untuk mendapatkan ID session dari short link
get_session_id() {
  local short_link="$1"
  log "INFO" "Memulai resolusi short link: $short_link"
  
  log "DEBUG" "Menjalankan curl request untuk mendapatkan lokasi redirect"
  local curl_response=$(curl -sI "$short_link")
  log "DEBUG" "Response header curl: $(echo "$curl_response" | tr '\n' '|')"
  
  local location=$(echo "$curl_response" | grep -i "Location:" | awk '{print $2}' | tr -d '\r')
  
  if [[ -n "$location" ]]; then
    log "INFO" "Link redirect ditemukan: $location"
    local session_id=$(echo "$location" | sed -n 's/.*session=\([^&]*\).*/\1/p')
    
    if [[ -n "$session_id" ]]; then
      log "INFO" "Session ID berhasil diekstrak: $session_id"
      echo "$session_id"
    else
      log "ERROR" "Tidak dapat menemukan parameter session di URL redirect"
      echo ""
    fi
  else
    log "ERROR" "Tidak mendapatkan redirect location dari short link"
    echo ""
  fi
}

# Fungsi utama untuk mengambil data livestream dan memutar dengan MPV
fetch_and_play() {
  log "INFO" "Memulai proses fetch dan play"
  
  log "DEBUG" "Memanggil fungsi get_session_id"
  local session_id=$(get_session_id "$SHORT_LINK")
  
  if [[ -z "$session_id" ]]; then
    log "ERROR" "Tidak dapat mengambil session ID dari short link"
    echo "Error: Could not retrieve session ID from the short link."
    return 1
  fi
  
  local url="https://live.shopee.co.id/api/v1/session/$session_id"
  log "INFO" "URL API yang akan diakses: $url"
  
  # Fetch data dari API
  log "DEBUG" "Menjalankan curl request ke API Shopee Live"
  local json_data=$(curl -s "$url")
  log "DEBUG" "Response size: $(echo -n "$json_data" | wc -c) bytes"
  
  # Simpan response API ke file untuk debugging
  echo "$json_data" > "shopee_api_response_$session_id.json"
  log "DEBUG" "Response API disimpan ke shopee_api_response_$session_id.json"
  
  local err_code=$(echo "$json_data" | jq -r '.err_code')
  log "INFO" "Error code dari API: $err_code"
  
  if [[ "$err_code" -ne 0 ]]; then
    local err_msg=$(echo "$json_data" | jq -r '.err_msg')
    log "ERROR" "Error fetching data: $err_msg"
    echo "Error fetching data: $err_msg"
    return 1
  fi
  
  log "DEBUG" "Mengekstrak play URL dan judul dari response API"
  local play_url=$(echo "$json_data" | jq -r '.data.play_urls[0]')
  local title=$(echo "$json_data" | jq -r '.data.session.title')
  local username=$(echo "$json_data" | jq -r '.data.session.username')
  local viewers=$(echo "$json_data" | jq -r '.data.session.viewer_count')
  
  log "INFO" "Informasi livestream:"
  log "INFO" "Judul: $title"
  log "INFO" "Username: $username"
  log "INFO" "Viewers: $viewers"
  log "INFO" "URL Stream: $play_url"
  
  echo "Judul: $title"
  echo "Username: $username"
  echo "Viewers: $viewers"
  echo "URL Stream: $play_url"
  echo "Memulai pemutaran dengan MPV..."
  
  log "INFO" "Memulai pemutaran dengan MPV..."
  
  # Putar dengan MPV
  # Sesuaikan parameter sesuai kebutuhan
  log "DEBUG" "Menjalankan command MPV"
  mpv --autofit=30% "$play_url" 2>&1 | tee -a "$LOG_FILE"
  local mpv_exit_code=${PIPESTATUS[0]}
  
  log "INFO" "MPV selesai dengan exit code: $mpv_exit_code"
  
  if [[ $mpv_exit_code -ne 0 ]]; then
    log "ERROR" "MPV keluar dengan error code: $mpv_exit_code"
  else
    log "INFO" "Pemutaran selesai dengan sukses"
  fi
}

# Validasi dependencies
log "INFO" "Memeriksa dependencies"

log "DEBUG" "Memeriksa MPV"
if command -v mpv >/dev/null 2>&1; then
  mpv_version=$(mpv --version | head -n 1)
  log "INFO" "MPV terinstall: $mpv_version"
else
  log "ERROR" "MPV tidak terinstall"
  echo "MPV tidak terinstall. Install dengan: apt install mpv"
  exit 1
fi

log "DEBUG" "Memeriksa jq"
if command -v jq >/dev/null 2>&1; then
  jq_version=$(jq --version)
  log "INFO" "jq terinstall: $jq_version"
else
  log "ERROR" "jq tidak terinstall"
  echo "jq tidak terinstall. Install dengan: apt install jq"
  exit 1
fi

log "DEBUG" "Memeriksa curl"
if command -v curl >/dev/null 2>&1; then
  curl_version=$(curl --version | head -n 1)
  log "INFO" "curl terinstall: $curl_version"
else
  log "ERROR" "curl tidak terinstall"
  echo "curl tidak terinstall. Install dengan: apt install curl"
  exit 1
fi

# Jalankan script
log "INFO" "Menjalankan fungsi fetch_and_play"
fetch_and_play
log "INFO" "Script selesai"
