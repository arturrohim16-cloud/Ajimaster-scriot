#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium Full Jantung (V3.1 - FIX)
# Multi-Port SSH WS, Xray, & Stunnel - By AJI VPN
# ==========================================

# --- KONFIGURASI UTAMA ---
DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. Update & Instal Software Utama
apt update -y && apt upgrade -y
apt install nginx jq python3 curl wget screen stunnel4 dropbear socat -y

# Instal Xray Core Resmi (Mencegah Unable to locate package)
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 2. Persiapan Sertifikat SSL
mkdir -p /etc/xray
mkdir -p /var/log/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" -keyout /etc/xray/xray.key -out /etc/xray/xray.crt
chmod +r /etc/xray/xray.crt
chmod +r /etc/xray/xray.key

# 3. Konfigurasi Xray (Port Internal 10001-10003)
cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": { "access": "/var/log/xray/access.log", "loglevel": "info" },
  "inbounds": [
    { "port": 10001, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [ { "id": "$ID_VMESS", "alterId": 0 } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } } },
    { "port": 10002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [ { "id": "$ID_VLESS_TR", "decryption": "none" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } } },
    { "port": 10003, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [ { "password": "$ID_VLESS_TR" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } } }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

# 4. Matikan Python WS Lama (Agar tidak bentrok port 2082 dengan Nginx)
systemctl stop ws-python 2>/dev/null
systemctl disable ws-python 2>/dev/null
rm -f /etc/systemd/system/ws-python.service

# 5. Konfigurasi Nginx (Sultan Multi-Port & Anti-Filter)
# Menghapus config default agar tidak conflict
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
rm -f /etc/nginx/conf.d/aji_vpn.conf
rm -f /etc/nginx/conf.d/vmess.conf

cat <<EOF > /etc/nginx/conf.d/xray.conf
# Blok HTTP & Anti-Filter 2082
server {
    listen 80;
    listen [::]:80;
    listen 2082;
    listen [::]:2082;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

# Blok HTTPS SSL 443
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    # SSH SSL Websocket
    location / {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }

    # XRAY PATHS
    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
}
EOF

# 6. Konfigurasi Dropbear (SSH Direct 22, 143, 109)
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
echo 'DROPBEAR_EXTRA_ARGS="-p 109 -p 22"' >> /etc/default/dropbear

# 7. Konfigurasi Stunnel4 (Port 444)
cat <<EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel.pid
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
[ssh]
accept = 444
connect = 127.0.0.1:143
EOF

# 8. Finalisasi & Start
systemctl daemon-reload
systemctl restart xray nginx stunnel4 dropbear
systemctl enable xray nginx stunnel4 dropbear

clear
echo -e "================================================="
echo -e "   INSTALLASI SELESAI - SEMUA PORT AKTIF!       "
echo -e "================================================="
echo -e " SSH Websocket : 80, 443, 2082 (Anti-Filter)"
echo -e " SSH SSL/TLS   : 444"
echo -e " SSH Direct    : 22, 143, 109"
echo -e " V2RAY/XRAY    : 80, 443 (Path: /vmess, /vless)"
echo -e "================================================="
echo -e " Domain        : $DOMAIN"
echo -e " Port Nginx    : 80, 443, 2082"
echo -e "================================================="
