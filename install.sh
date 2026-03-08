#!/bin/bash

if [ "${EUID}" -ne 0 ]; then
echo "Jalankan sebagai ROOT"
exit 1
fi

clear
echo "AUTO INSTALL VPN SERVER"

apt update -y
apt upgrade -y

apt install -y \
curl wget nano vim git unzip zip screen jq cron \
iptables fail2ban nginx dropbear stunnel4 socat certbot

IP=$(curl -s ipinfo.io/ip)

echo "IP VPS : $IP"

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# ======================
# INPUT DOMAIN
# ======================

read -p "Masukkan domain yang sudah pointing ke VPS: " DOMAIN

mkdir -p /etc/xray
echo $DOMAIN > /etc/xray/domain

echo "Domain aktif : $DOMAIN"

# ======================
# INSTALL XRAY
# ======================

bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

# ======================
# INSTALL SSH WS
# ======================

wget -q https://raw.githubusercontent.com/NevermoreSSH/Blueblue/main/ssh-vpn.sh
chmod +x ssh-vpn.sh
./ssh-vpn.sh

# ======================
# SSL
# ======================

systemctl stop nginx

certbot certonly \
--standalone \
-d $DOMAIN \
--non-interactive \
--agree-tos \
-m admin@$DOMAIN

systemctl start nginx

systemctl restart nginx
systemctl restart xray
systemctl restart dropbear

echo ""
echo "INSTALL SELESAI"
echo "Domain : $DOMAIN"
echo "IP : $IP"
echo "SSL : AKTIF"
