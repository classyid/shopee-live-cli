# Shopee Live CLI

Aplikasi command line sederhana untuk menonton livestream Shopee langsung dari terminal menggunakan MPV player.

![Shopee Live CLI](https://via.placeholder.com/800x400?text=Shopee+Live+CLI)

## Fitur

- Menonton Shopee Live langsung dari terminal
- Dukungan untuk link pendek Shopee
- Antarmuka sederhana berbasis command line
- Pemutaran video dengan MPV player
- Otomatis mengekstrak informasi streaming dari API Shopee

## Prasyarat

Script ini membutuhkan beberapa dependencies:
- `bash` (v4+)
- `curl`
- `jq`
- `mpv`

## Instalasi

```bash
# Clone repository
git clone https://github.com/classyid/shopee-live-cli.git
cd shopee-live-cli

# Berikan izin eksekusi
chmod +x shopee_player.sh

# Pastikan dependencies terinstall
sudo apt install curl jq mpv
```

## Penggunaan

```bash
./shopee_player.sh <shopee_short_link>
```

Contoh:
```bash
./shopee_player.sh https://shope.ee/live/abcd1234
```

## Cara Kerja

1. Script menerima short link Shopee Live sebagai input
2. Mengekstrak ID sesi dari link tersebut
3. Mengambil data streaming dari API Shopee
4. Memutar video livestream menggunakan MPV player

## Kustomisasi

Anda dapat mengubah parameter MPV di dalam script untuk menyesuaikan pengalaman menonton:

```bash
# Ubah ukuran player (saat ini 30%)
mpv --autofit=30% "$play_url"

# Contoh parameter lain yang bisa ditambahkan:
# --volume=50
# --fullscreen
# --no-border
```

## Troubleshooting

**Error: Could not retrieve session ID from the short link**
- Pastikan link yang diberikan adalah link Shopee Live yang valid
- Periksa koneksi internet Anda

**MPV tidak terinstall**
- Install MPV: `sudo apt install mpv`

**jq tidak terinstall**
- Install jq: `sudo apt install jq`

## Kontribusi

Kontribusi selalu diterima! Silakan fork repository ini, buat perubahan, dan submit pull request.

## Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

## Disclaimer

Script ini tidak terafiliasi dengan Shopee dan dibuat hanya untuk tujuan pendidikan. Gunakan dengan bijak dan hormati syarat dan ketentuan Shopee.
