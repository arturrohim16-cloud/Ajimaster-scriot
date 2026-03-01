#!/bin/bash
# ==========================================
# Auto-Installer VPN AJI STORE - SUPER STABLE
# UPDATE: PYTHON WS FIX & AUTO-LOCK CONFIG
# ==========================================

DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. Bersihkan & Buka Kunci (Penting agar script bisa menulis ulang)
chattr -i /etc/nginx/conf.d/xray.conf 2>/dev/null
chattr -i /usr/local/etc/xray/config.json 2>/dev/null
chattr -i /etc/stunnel/stunnel.conf 2>/dev/null
systemctl stop nginx xray dropbear stunnel4 ws-dropbear 2>/dev/null

# 2. Instalasi Core & Dependency
apt update -y
apt install nginx jq curl wget stunnel4 dropbear socat python3 -y
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 3. Perbaikan Script Python WS (Python 3 Version)
rm -f /usr/local/bin/ws-dropbear
cat <<EOF > /usr/local/bin/ws-dropbear
import socket, threading, _thread

def handle(client_sock, addr):
    try:
        target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_sock.connect(('127.0.0.1', 143))
        def forward(source, destination):
            while True:
                try:
                    data = source.recv(4096)
                    if not data: break
                    destination.sendall(data)
                except: break
        threading.Thread(target=forward, args=(client_sock, target_sock), daemon=True).start()
        threading.Thread(target=forward, args=(target_sock, client_sock), daemon=True).start()
    except:
        client_sock.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 8880))
    server.listen(100)
    while True:
        client, addr = server.accept()
        try:
            data = client.recv(1024)
            client.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            _thread.start_new_thread(handle, (client, addr))
        except:
            client.close()

if __name__ == "__main__":
    main()
EOF
chmod +x /usr/local/bin/ws-dropbear

# Buat Service Python WS
cat <<EOF > /etc/systemd/system/ws-dropbear.service
[Unit]
Description=Python SSH Websocket
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ws-dropbear 8880
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 4. SSL & Xray Config (Super Fix)
mkdir -p /etc/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" \
    -keyout /etc/xray/xray.key -out /etc/xray/xray.crt

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

# 5. Config Nginx (Lock Path & WebSocket)
cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen 2082;
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;

    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }

    location / {
        proxy_pass http://127.0.0.1:8880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

# 6. Stunnel Config (Port 444)
cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
[ssh-ssl]
accept = 444
connect = 127.0.0.1:143
EOF

# 7. Finalisasi & LOCK (Kunci File)
rm -f /etc/nginx/sites-enabled/default
systemctl daemon-reload
systemctl enable ws-dropbear xray nginx stunnel4 dropbear
systemctl restart ws-dropbear xray nginx stunnel4 dropbear

# --- BAGIAN SUPER LOCK ---
chattr +i /etc/nginx/conf.d/xray.conf
chattr +i /usr/local/etc/xray/config.json
chattr +i /etc/stunnel/stunnel.conf

echo "BOMM!! SEMUA HIJAU & DIKUNCI KING! AMAN DARI HAPUS USER!"
