#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium AJI STORE (V3.2)
# FIX Xray OFF & Multi-Port Anti-Filter
# ==========================================

# --- KONFIGURASI ---
DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. Cleaning & Update
apt update -y && apt upgrade -y
apt install nginx jq python3 curl wget stunnel4 dropbear socat -y

# 2. INSTAL XRAY (Official Script - Fix ERROR OFF)
echo -e "Memasang Xray Core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 3. Sertifikat SSL & Folder Log
mkdir -p /etc/xray
mkdir -p /var/log/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" -keyout /etc/xray/xray.key -out /etc/xray/xray.crt

# 4. Konfigurasi Xray (Port Internal)
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

# 5. Konfigurasi Nginx (Sultan Anti-Filter)
rm -f /etc/nginx/sites-enabled/default
cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen 2082;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
}
server {
    listen 443 ssl http2;
    server_name _;
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    location / {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
}
EOF

# 6. Dropbear & Stunnel
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
[ssh]
accept = 444
connect = 127.0.0.1:143
EOF

# 7. Finalisasi
systemctl stop ws-python 2>/dev/null
systemctl disable ws-python 2>/dev/null
systemctl daemon-reload
systemctl restart xray nginx stunnel4 dropbear
systemctl enable xray nginx stunnel4 dropbear

echo "INSTALASI BERHASIL! CEK MENU SEKARANG."
