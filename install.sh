#!/bin/bash
# ==========================================
# Script Auto-Install VPS - AJI SYSTEM
# ==========================================

# // Root Checking
if [ "${EUID}" -ne 0 ]; then
    echo -e "Please Run This Script As Root User !"
    exit 1
fi

# // Export Color & Information
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export NC='\033[0m'
export INFO="[${YELLOW} INFO ${NC}]"
export OKEY="[${GREEN} OKEY ${NC}]"

# // Set Timezone
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

clear
echo -e "${OKEY} Memulai Persiapan Instalasi..."

# 1. UPDATE & INSTALL ESSENTIAL TOOLS
# Dipasang di awal agar semua fungsi (wget, curl, python) tersedia
apt update -y
apt upgrade -y
apt install -y jq curl wget sed socat python3 python3-is-python3 \
binutils build-essential cron lsb-release tar zip unzip htop net-tools

# 2. INPUT DOMAIN (Wajib di awal agar SSL tidak error)
echo -e "======================================"
read -p " Masukkan Domain VPS Anda: " DOMAIN
echo "--------------------------------------"
if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}Error: Domain tidak boleh kosong!${NC}"
    exit 1
fi
mkdir -p /etc/xray
echo "$DOMAIN" > /etc/xray/domain

# 3. CLEANING OLD SYSTEM (Opsional)
# Menghapus instalasi lama agar tidak konflik
apt remove --purge nginx* dropbear* stunnel* -y
apt autoremove -y
rm -rf /etc/nginx /usr/bin/xray /etc/xray/config.json

# 4. PREPARE DIRECTORIES
# Membuat folder yang dibutuhkan sebelum download file
mkdir -p /etc/xray
mkdir -p /usr/bin/xray
mkdir -p /var/lib/scrz-prem/
mkdir -p /usr/local/etc/xray

# 5. INSTALL CORE SERVICES (Silakan isi link script instalasi kamu nanti)
echo -e "${INFO} Memasang Core Services..."

# [CONTOH PENEMPATAN LINK]
 wget -q -O ssh-vpn.sh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ssh-vpn.sh" && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
 wget -q -O Ins-xray.sh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/Ins-xray.sh" && chmod +x Ins-xray.sh && ./Ins-xray.sh

echo -e "${OKEY} Core Services Terpasang."

# 6. DOWNLOAD MENU & COMMANDS
# Folder /usr/bin adalah tempat perintah terminal (menu, add-ws, dll)
echo -e "${INFO} Mendownload Perintah Manajemen..."

# [CONTOH PENEMPATAN DOWNLOAD COMMAND]
# wget -q -O /usr/bin/menu "LINK_MENU"
# chmod +x /usr/bin/menu

# 7. SETUP SSL CERTIFICATE (CERTBOT)
# Dilakukan setelah Nginx terpasang tapi sebelum dikonfigurasi penuh
echo -e "${INFO} Mengatur SSL Certificate untuk $DOMAIN..."
apt install certbot -y
systemctl stop nginx
certbot certonly --standalone --preferred-challenges http \
-d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# 8. SETUP CRONJOB
echo -e "${INFO} Mengatur Auto-Reboot & Cronjob..."
cat > /etc/cron.d/re_otm << END
0 5 * * * root /sbin/reboot
2 0 * * * root /usr/bin/xp
END
systemctl restart cron

# 9. FINAL RESTART & CLEANUP
echo -e "${INFO} Merestart Semua Layanan..."
# Pastikan service sudah ada sebelum direstart
systemctl daemon-reload
systemctl enable nginx
systemctl enable xray
systemctl restart nginx
systemctl restart xray

# 10. SHOW INSTALLATION LOG
clear
echo "================================================="
echo "   INSTALLATION COMPLETED SUCCESSFULY"
echo "================================================="
echo " Domain  : $DOMAIN"
echo " IP      : $(curl -s ifconfig.me)"
echo " Service : SSH, XRAY, NGINX, SSL"
echo "================================================="
echo " Ketik 'menu' untuk melihat daftar perintah."
echo ""
read -p "Tekan [Enter] untuk Reboot VPS..."
reboot
