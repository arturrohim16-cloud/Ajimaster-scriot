#!/bin/bash
# ==========================================
# Auto-Installer VPN AJI STORE - TOTAL REMAKE
# Gateway: Nginx (80, 443) | UDP Custom
# ==========================================

DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. CLEANING & UNLOCK (Hapus Stunnel karena sudah lewat Nginx)
echo "Cleaning old configs..."
systemctl stop nginx xray dropbear stunnel4 ws-dropbear 2>/dev/null
chattr -i /etc/nginx/conf.d/xray.conf /usr/local/etc/xray/config.json 2>/dev/null

# 2. INSTALL DEPENDENCIES
apt update -y
apt install nginx jq curl wget dropbear socat python3 net-tools -y

# Install Xray Core
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Install UDP Custom (Binary sakti untuk UDP 1-65535)
wget -q -O /usr/bin/udp-custom https://github.com/up-the-limit/udp-custom/raw/main/udp-custom-linux-amd64
chmod +x /usr/bin/udp-custom
cat <<EOF > /etc/udp/config.json
{
  "listen": ":3671",
  "stream_buffer": 33554432,
  "receive_buffer": 33554432,
  "auth": {
    "type": "password",
    "password": "1"
  }
}
EOF

# 3. PYTHON WS (Jembatan SSH Internal)
cat <<EOF > /usr/local/bin/ws-dropbear
import socket, threading
def forward(src, dst):
    try:
        while True:
            buf = src.recv(4096)
            if not buf: break
            dst.sendall(buf)
    except: pass
def handle(client_sock, addr):
    try:
        data = client_sock.recv(1024).decode(errors='ignore')
        if 'Upgrade: websocket' in data:
            target_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target_sock.connect(('127.0.0.1', 143))
            client_sock.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            threading.Thread(target=forward, args=(client_sock, target_sock), daemon=True).start()
            forward(target_sock, client_sock)
    except: pass
    finally: client_sock.close()
def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', 8880))
    server.listen(100)
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle, args=(client, addr), daemon=True).start()
if __name__ == "__main__": main()
EOF
chmod +x /usr/local/bin/ws-dropbear

# 4. NGINX CONFIG (The Master Gateway)
cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen 443 ssl http2;
    server_name $DOMAIN;
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    
    # VMESS, VLESS, TROJAN (Tetap di Path masing-masing)
    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }

    # SSH WEBSOCKET (Jalur Utama Root /)
    location / {
        proxy_pass http://127.0.0.1:8880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_buffering off;
    }
}
EOF

# 5. FINALIZING
systemctl daemon-reload
systemctl enable ws-dropbear xray nginx dropbear
systemctl restart ws-dropbear xray nginx dropbear

# --- LOCK ---
chattr +i /etc/nginx/conf.d/xray.conf
chattr +i /usr/local/etc/xray/config.json

echo "-------------------------------------------------------"
echo "  REMBOK TOTAL SELESAI! SEMUA SATU PINTU KING!         "
echo "  PORT 80 & 443: VMESS, VLESS, TROJAN, SSH WS          "
echo "  UDP CUSTOM   : AKTIF (1-65535)                       "
echo "-------------------------------------------------------"
