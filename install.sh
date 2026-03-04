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

# 1. Bersihkan sisa-sisa python sebelumnya
pkill -f proxy-aji
pkill -f python3

# 2. Jalankan Proxy Universal di Port 8880
cat <<EOF > /usr/bin/proxy-aji
import socket, threading
def bridge(source, destination):
    while True:
        try:
            data = source.recv(8192)
            if not data: break
            destination.sendall(data)
        except: break
def handle_client(client_soc):
    try:
        request = client_soc.recv(8192)
        # Respon 101 WAJIB agar HTTP Custom tidak Timeout/Nanggung
        client_soc.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        server_soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_soc.connect(('127.0.0.1', 143)) # Menuju Dropbear yang sudah aktif
        threading.Thread(target=bridge, args=(client_soc, server_soc), daemon=True).start()
        bridge(server_soc, client_soc)
    except: pass
    finally: client_soc.close()
def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', 8880))
    server.listen(500)
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client,), daemon=True).start()
if __name__ == '__main__':
    main()
EOF

# 3. Jalankan di background
nohup python3 /usr/bin/proxy-aji > /dev/null 2>&1 &

# 4. Cek Verifikasi Akhir
netstat -tunlp | grep :8880

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
