#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium AJI STORE (V3.3)
# FIX TOTAL: Nginx & Xray Stability
# ==========================================

DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. Update & Install
apt update -y && apt upgrade -y
apt install nginx jq python3 curl wget stunnel4 dropbear socat -y

# 2. Install Xray Official (Pasti Hijau)
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 3. Sertifikat & Folder
mkdir -p /etc/xray
mkdir -p /var/log/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" -keyout /etc/xray/xray.key -out /etc/xray/xray.crt
chmod +r /etc/xray/xray.crt
chmod +r /etc/xray/xray.key

# 4. Config Xray (Bersih & Ringan)
cat <<EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [
    { "port": 10001, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [ { "id": "$ID_VMESS" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } } },
    { "port": 10002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [ { "id": "$ID_VLESS_TR" } ], "decryption": "none" }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } } },
    { "port": 10003, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [ { "password": "$ID_VLESS_TR" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } } }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

# 5. Nginx Sultan (Gabungan Anti-Filter & SSL)
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/xray.conf

cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen [::]:80;
    listen 2082;
    listen [::]:2082;
    server_name _;

    # Jalur SSH WS Anti-Filter
    location / {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_read_timeout 3600s;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Jalur SSL SSH & Xray
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

# 6. Dropbear (Port 143, 22, 109)
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
grep -q "-p 109 -p 22" /etc/default/dropbear || echo 'DROPBEAR_EXTRA_ARGS="-p 109 -p 22"' >> /etc/default/dropbear

# 7. Stunnel4
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

# 8. Finalisasi
systemctl daemon-reload
systemctl restart xray nginx stunnel4 dropbear
systemctl enable xray nginx stunnel4 dropbear

clear
echo "========================================="
echo "   INSTALLASI SELESAI - SEMUA HIJAU!     "
echo "========================================="
