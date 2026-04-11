#!/bin/bash

# Konfigurasi Cloudflare
CF_ID="ajijainalganteng@gmail.com"
CF_KEY="MASUKKAN_API_KEY_ANDA_DISINI" # Pastikan API Key diisi

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "    AUTO DOMAIN DETECTION   "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install dependency
apt update -y && apt install -y jq curl

# Ambil IP VPS Publik
IP=$(curl -s ifconfig.me)

echo "IP VPS Anda: $IP"
echo "Mencari domain yang terhubung di Cloudflare..."

# 1. Ambil semua Zone ID yang ada di akun Cloudflare
ZONES=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r '.result[].id')

FOUND_DOMAIN=""

# 2. Scan setiap zone untuk mencari record yang mengarah ke IP VPS ini
for ZONE in $ZONES; do
    # Cari DNS Record tipe A yang isinya adalah IP VPS ini
    SEARCH=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A&content=${IP}" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json")
    
    MATCH=$(echo $SEARCH | jq -r '.result[0].name')
    
    if [[ "$MATCH" != "null" && "$MATCH" != "" ]]; then
        FOUND_DOMAIN=$MATCH
        break
    fi
done

# Cek apakah domain ditemukan
if [[ -z "$FOUND_DOMAIN" ]]; then
    echo "❌ Error: Tidak ditemukan domain di Cloudflare yang di-pointing ke $IP"
    echo "Silakan pointing manual dulu di dashboard Cloudflare."
    exit 1
fi

echo "✅ Domain ditemukan: $FOUND_DOMAIN"

# Setup Folder & Simpan Data
mkdir -p /var/lib/scrz-prem
mkdir -p /etc/xray
mkdir -p /var/lib/premium-script

echo "$FOUND_DOMAIN" > /root/domain
echo "$FOUND_DOMAIN" > /etc/xray/domain
echo "IP=$FOUND_DOMAIN" > /var/lib/scrz-prem/ipvps.conf
echo "IP=$FOUND_DOMAIN" > /var/lib/premium-script/ipvps.conf

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup Berhasil Disimpan   "
echo "  Domain: $FOUND_DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
