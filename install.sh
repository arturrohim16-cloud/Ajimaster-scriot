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
wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/set-br.sh && chmod +x set-br.sh && ./set-br.sh

wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/install-jembut.sh && chmod +x install-jembut.sh && ./install-jembut.sh

 wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
 wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/Ins-xray.sh && chmod +x Ins-xray.sh && ./Ins-xray.sh

echo -e "${OKEY} Core Services Terpasang."

# 6. DOWNLOAD MENU & COMMANDS
# Folder /usr/bin adalah tempat perintah terminal (menu, add-ws, dll)
wget -q -0 /bin/bash/add-vmess "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-vmess.sh" 
wget -q -0 /bin/bash/add-vless "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-vless.sh" 
wget -q -0 /bin/bash/add-tr "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-tr.sh" 
wget -q -0 /bin/bash/add-ws "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-ws.sh" 
wget -q -O /bin/bash/add-ssws "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-ssws.sh" 
wget -q -O /bin/bash/add-socks "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-socks.sh" 
wget -q -O /bin/bash/add-trgo "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-trgo.sh" 
wget -q -O /bin/bash/autoreboot "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/autoreboot.sh" 
wget -q -O /bin/bash/restart "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/restart.sh" 

#wget -q -O /usr/bin/tendang "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/tendang.sh

#wget -q -O /usr/bin/clearlog "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/clearlog.sh

wget -q -O /bin/bash/runing "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/runing.sh" 
wget -q -O /bin/bash/cek-trafik "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/cek-trafik.sh" 
wget -q -O /bin/bash/speedtes-cli "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/speedtes_cli.py" 
wget -q -O /bin/bash/cek-badwing "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/cek-badwing.sh" 
wget -q -O /bin/bash/ram "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ram.sh" 
wget -q -O /bin/bash/limit-speed "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/limit-speed.sh"
wget -q -O /bin/bash/menu-vless "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-vless.sh" 
wget -q -O /bin/bash/menu-vmess "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-vmess.sh" 
wget -q -O /bin/bash/menu-socks "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-socks.sh" 
wget -q -O /bin/bash/menu-ss "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-ss.sh" 
wget -q -O /bin/bash/menu-trojan "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-trojan.sh" 
wget -q -O /bin/bash/menu-trgo "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-trgo.sh" 
wget -q -O /bin/bash/menu-ssh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-ssh.sh" 

#wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bekap-tg.sh

#wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/menu-bckp-github.sh

#wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bckpbot.sh

wget -q -O /bin/bash/usernew "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/usernew.sh" 
wget -q -O /bin/bash/menu "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu.sh" 
wget -q -O /bin/bash/menu1 "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu1.sh" 
wget -q -O /bin/bash/webbin "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/webbin.sh" 
wget -q -O /bin/bash/xp "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/xp.sh" 

#wget -q -O /usr/bin/update "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/update.sh

wget -q -O /bin/bash/dns "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/dns.sh" 
wget -q -O /bin/bash/netf "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/netf.sh" 
wget -q -O /bin/bash/bber "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/bbr.sh" 
wget -q -O /bin/bash/del-xray "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/del-xray.sh" 
wget -q -O /bin/bash/user-xray "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/user-xray.sh" 

echo -e "${INFO} Mendownload Perintah Manajemen..."

# [CONTOH PENEMPATAN DOWNLOAD COMMAND]
chmod +x /bin/bash/add-ws
chmod +x /bin/bash/add-ssws
chmod +x /bin/bash/add-socks
chmod +x /bin/bash/add-vless
chmod +x /bin/bash/add-tr
chmod +x /bin/bash/add-trgo
chmod +x /bin/bash/add-vmess
chmod +x /bin/bash/usernew
chmod +x /bin/bash/autoreboot
chmod +x /bin/bash/restart
#chmod +x /bin/bash/tendang
#chmod +x /bin/bash/clearlog
chmod +x /bin/bash/runing
chmod +x /bin/bash/cek-trafik
chmod +x /bin/bash/speedtes-cli
chmod +x /bin/bash/cek-badwing
chmod +x /bin/bash/ram
chmod +x /bin/bash/limit-speed
chmod +x /bin/bash/menu-vless
chmod +x /bin/bash/menu-vmess
chmod +x /bin/bash/menu-ss
chmod +x /bin/bash/menu-socks
chmod +x /bin/bash/menu-trojan
chmod +x /bin/bash/menu-trgo
chmod +x /bin/bash/menu-ssh
#chmod +x /bin/bash/menu-bckp
chmod +x /bin/bash/menu
chmod +x /bin/bash/menu1
#chmod +x /bin/bash/bckp
chmod +x /bin/bash/webbin
chmod +x /bin/bash/xp
#chmod +x /bin/bash/update
chmod +x /bin/bash/dns
chmod +x /bin/bash/netf
chmod +x /bin/bash/bbr
chmod +x /bin/bash/del-xray
chmod +x /bin/bash/user-xray

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
