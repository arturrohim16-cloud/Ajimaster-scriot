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
wget -q -0 add-vmess.sh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-vmess.sh" && chmod +x add-vmess.sh && ./add-vmess.sh

wget -q -0 add-vless.sh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-vless.sh" && chmod +x add-vless.sh && ./add-vless.sh

wget -q -0 add-tr.sh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-tr.sh" && chmod +x add-tr.sh && ./add-tr.sh

wget -q -0 add-ws.sh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-ws.sh" && chmod +x add-ws.sh && ./add-ws.sh

wget -q -O add-ssws "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-ssws.sh" && chmod +x add-ssws.sh && ./add-ssws.sh

wget -q -O add-socks "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-socks.sh" && chmod +x add-socks.sh && ./add-socks.sh

wget -q -O add-trgo "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-trgo.sh" && chmod +x add-trgo.sh && ./add-tego.sh

wget -q -O autoreboot "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/autoreboot.sh" && chmod +x autoreboot.sh && ./autoreboot.sh

wget -q -O restart "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/restart.sh" && chmod +x restart.sh && ./restart.sh

#wget -q -O /usr/bin/tendang "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/tendang.sh"

#wget -q -O /usr/bin/clearlog "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/clearlog.sh"

wget -q -O /usr/bin/running "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/runing.sh" && chmod +x runing.sh && ./runing.sh

wget -q -O /usr/bin/cek-trafik "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/cek-trafik.sh" && chmod +x cek-trafik.sg && ./cek-trafik.sh

wget -q -O /usr/bin/cek-speed "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/speedtes_cli.py" && chmod +x speedtes_cli.py && ./speedtes_cli.py

wget -q -O /usr/bin/cek-bandwidth "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/cek-badwing.sh" && chmod +x cek-badwing.sh && ./cek-badwing.sh

wget -q -O /usr/bin/cek-ram "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ram.sh" && chmod +x ram.sh && ./ram.sh

wget -q -O /usr/bin/limit-speed "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/limit-speed.sh" && chmod +x limit-speed.sh && ./limit-speed.sh

wget -q -O /usr/bin/menu-vless "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-vless.sh" && chmod +x menu-vless.sh && ./menu-vless.sh

wget -q -O /usr/bin/menu-vmess "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-vmess.sh" && chmod +x menu-vmess.sh && ./menu-vmess.sh

wget -q -O /usr/bin/menu-socks "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-socks.sh" && chmod +x menu-socks.sh && ./menu-socks.sh

wget -q -O /usr/bin/menu-ss "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-ss.sh" && chmod +x menu-ss.sh && ./ menu-ss.sh

wget -q -O /usr/bin/menu-trojan "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-trojan.sh" && chmod +x menu-trojan.sh && ./menu-trojan.sh

wget -q -O /usr/bin/menu-trgo "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-trgo.sh" && chmod +x menu-trgo.sh && ./menu-trgo.sh

wget -q -O /usr/bin/menu-ssh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-ssh.sh" && chmod +x menu-ssh.sh && ./menu-ssh

#wget -q -O /usr/bin/menu-bckp "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bekap-tg.sh"

#wget -q -O /usr/bin/menu-bckp "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/menu-bckp-github.sh"

#wget -q -O /usr/bin/bckp "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bckpbot.sh"

wget -q -O /usr/bin/usernew "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/usernew.sh" && chmod +x usernew.sh && ./usernew.sh

wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu" && chmod +x menu.sh && ./menu.sh

wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu1.sh" && chmod +x menu1.sh && ./menu1.sh

wget -q -O /usr/bin/wbm "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/webbin.sh" && chmod +x webbin.sh && ./webbin.sh

wget -q -O /usr/bin/xp "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/xp.sh" && chmod +x xp.sh && ./xp.sh

#wget -q -O /usr/bin/update "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/update.sh"

wget -q -O /usr/bin/dns "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/dns.sh" && chmod +x dns.sh && ./dns.sh

wget -q -O /usr/bin/netf "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/netf.sh" && chmod +x netf.sh && ./netf.sh

wget -q -O /usr/bin/bbr "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bbr.sh" && chmod +x bbr.sh && ./bbr.sh

wget -q -O /usr/bin/del-xrays "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/del-xray.sh" && chmod +x del-xray.sh && ./del-xray.sh

wget -q -O /usr/bin/user-xrays "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/user-xray.sh" && chmod +x user-xray.sh && ./user-xray.sh

echo -e "${INFO} Mendownload Perintah Manajemen..."

# [CONTOH PENEMPATAN DOWNLOAD COMMAND]
chmod +x /usr/bin/add-ws
chmod +x /usr/bin/add-ssws
chmod +x /usr/bin/add-socks
chmod +x /usr/bin/add-vless
chmod +x /usr/bin/add-tr
chmod +x /usr/bin/add-trgo
chmod +x /usr/bin/usernew
chmod +x /usr/bin/autoreboot
chmod +x /usr/bin/restart
chmod +x /usr/bin/tendang
chmod +x /usr/bin/clearlog
chmod +x /usr/bin/running
chmod +x /usr/bin/cek-trafik
chmod +x /usr/bin/cek-speed
chmod +x /usr/bin/cek-bandwidth
chmod +x /usr/bin/cek-ram
chmod +x /usr/bin/limit-speed
chmod +x /usr/bin/menu-vless
chmod +x /usr/bin/menu-vmess
chmod +x /usr/bin/menu-ss
chmod +x /usr/bin/menu-socks
chmod +x /usr/bin/menu-trojan
chmod +x /usr/bin/menu-trgo
chmod +x /usr/bin/menu-ssh
chmod +x /usr/bin/menu-bckp
chmod +x /usr/bin/menu
chmod +x /usr/bin/bckp
chmod +x /usr/bin/wbm
chmod +x /usr/bin/xp
chmod +x /usr/bin/update
chmod +x /usr/bin/dns
chmod +x /usr/bin/netf
chmod +x /usr/bin/bbr
chmod +x /usr/bin/del-xrays
chmod +x /usr/bin/user-xrays

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
