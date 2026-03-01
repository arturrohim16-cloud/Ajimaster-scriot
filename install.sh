#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium Full Jantung (V3)
# Multi-Port SSH WS, Xray, & Stunnel - By AJI VPN
# ==========================================

# --- KONFIGURASI UTAMA ---
TOKEN="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"
REPO_URL="https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/main"
DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. Update & Instal Semua Software
apt update -y && apt upgrade -y
apt install nginx xray jq python3 python3-pip curl wget screen stunnel4 dropbear socat dbus-x11 -y

# 2. Persiapan Sertifikat SSL
mkdir -p /etc/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" -keyout /etc/xray/xray.key -out /etc/xray/xray.crt
chmod +r /etc/xray/xray.crt
chmod +r /etc/xray/xray.key

# 3. Konfigurasi Xray (Port Internal)
cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": { "access": "/var/log/xray/access.log", "loglevel": "info" },
  "inbounds": [
    { "port": 10001, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [ { "id": "$ID_VMESS", "alterId": 0 } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } } },
    { "port": 10002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [ { "id": "$ID_VLESS_TR", "decryption": "none" } ], "decryption": "none" }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } } },
    { "port": 10003, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [ { "password": "$ID_VLESS_TR" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } } }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

# 4. Instalasi SSH Websocket Python (Port 2082 & Proxying)
echo -e "Memasang SSH Websocket Python..."
wget -O /usr/local/bin/ws-python "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/main/Scriptku/ws-python.py" 2>/dev/null
if [ $? -ne 0 ]; then
# Jika file download gagal, buat script python sederhana di tempat
cat <<EOF > /usr/local/bin/ws-python
import socket, threading, sys
def proxy(client, address):
    try:
        data = client.recv(1024).decode()
        if 'Upgrade: websocket' in data:
            client.send(b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n')
            target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target.connect(('127.0.0.1', 143)) # Connect ke Dropbear
            def forward(src, dst):
                try:
                    while True:
                        d = src.recv(4096)
                        if not d: break
                        dst.send(d)
                except: pass
            threading.Thread(target=forward, args=(client, target)).start()
            threading.Thread(target=forward, args=(target, client)).start()
    except: pass
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('0.0.0.0', 2082))
s.listen(1000)
while True:
    c, addr = s.accept()
    threading.Thread(target=proxy, args=(c, addr)).start()
EOF
fi
chmod +x /usr/local/bin/ws-python

# Buat Systemd Service untuk SSH WS agar auto-start
cat <<EOF > /etc/systemd/system/ws-python.service
[Unit]
Description=SSH Websocket Python
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/ws-python
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable ws-python

# 5. Konfigurasi Nginx (Jalur Sultan Multi-Port & Anti-Filter 2082)
cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    listen 2082;         # <--- Menambahkan listen 2082 di sini
    listen [::]:2082;    # <--- Menambahkan listen 2082 IPv6
    server_name $DOMAIN;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    # SSH Websocket (Jalur Port 80, 443 via Path /ssh-ws DAN Port 2082 Direct)
    location / {
        # Jika bukan path xray, maka otomatis dilempar ke SSH (Anti-Filter)
        if (\$http_upgrade != "websocket") {
            return 301 https://\$host\$request_uri;
        }
        proxy_pass http://127.0.0.1:143; # Arahkan langsung ke Dropbear
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Backup Path lama agar tidak error
    location /ssh-ws {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    # XRAY PATHS
    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
}
EOF

# 6. Konfigurasi Dropbear & Stunnel (Port 22, 143, 109, 444)
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
echo 'DROPBEAR_EXTRA_ARGS="-p 109 -p 22"' >> /etc/default/dropbear

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

# 7. Finalisasi & Restart
systemctl daemon-reload
systemctl restart xray nginx stunnel4 dropbear ws-python
systemctl enable xray nginx stunnel4 dropbear ws-python

echo -e "================================================="
echo -e "   INSTALLASI SELESAI - SEMUA PORT AKTIF!       "
echo -e "================================================="
echo -e " SSH Websocket : 80, 443 (Path: /ssh-ws), 2082"
echo -e " SSH SSL/TLS   : 444"
echo -e " SSH Direct    : 22, 143, 109"
echo -e " V2RAY/XRAY    : 80, 443"
echo -e "================================================="
