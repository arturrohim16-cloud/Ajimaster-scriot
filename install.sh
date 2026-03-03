#!/bin/bash
# ==========================================
# Auto-Installer VPN AJI STORE - PORT FIX
# Nginx (80, 443, 2082) | Xray WS Internal
# ==========================================

# --- CONFIG DATA ---
DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. CLEANING & UNLOCK
echo "Cleaning old configs..."
chattr -i /etc/nginx/conf.d/xray.conf /usr/local/etc/xray/config.json /etc/stunnel/stunnel.conf 2>/dev/null
systemctl stop nginx xray dropbear stunnel4 ws-dropbear 2>/dev/null

# 2. INSTALL DEPENDENCIES & CORE
echo "Installing Dependencies..."
apt update -y
apt install nginx jq curl wget stunnel4 dropbear socat python3 net-tools -y

# Install Xray Core Official
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 3. PYTHON WS SETUP (Port 8880 Internal)
echo "Setting up Python WS..."
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

# Create Service Python WS
cat <<EOF > /etc/systemd/system/ws-dropbear.service
[Unit]
Description=Python SSH Websocket
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/ws-dropbear
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

# 4. SSL GENERATOR
mkdir -p /etc/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
-subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" \
-keyout /etc/xray/xray.key -out /etc/xray/xray.crt

# 5. XRAY CONFIG (Internal Ports)
echo "Configuring Xray..."
cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": {"loglevel": "info"},
  "inbounds": [
    {
      "port": 10001, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": {"clients": [{"id": "$ID_VMESS"}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}}
    },
    {
      "port": 10002, "listen": "127.0.0.1", "protocol": "vless",
      "settings": {"clients": [{"id": "$ID_VLESS_TR"}], "decryption": "none"},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vless"}}
    },
    {
      "port": 10003, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": {"clients": [{"password": "$ID_VLESS_TR"}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/trojan"}}
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# 6. NGINX CONFIG (Master Port 80, 443, 2082)
echo "Cleaning Ports and Configuring Nginx..."
# Paksa kosongkan port sebelum start
fuser -k 80/tcp 443/tcp 2082/tcp 2>/dev/null 

cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen 2082;
    listen 443 ssl http2;
    server_name $DOMAIN;
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;

    # VMESS
    location /vmess {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
    # VLESS
    location /vless {
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
    # TROJAN
    location /trojan {
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
    # SSH WS
    location / {
        proxy_pass http://127.0.0.1:8880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

# 7. STUNNEL CONFIG (Port 444)
echo "Configuring Stunnel..."
cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
[ssh-ssl]
accept = 444
connect = 127.0.0.1:8880
EOF

# 8. FINALIZING SERVICES
echo "Finalizing..."
systemctl daemon-reload
systemctl enable ws-dropbear xray nginx stunnel4 dropbear
systemctl restart ws-dropbear xray nginx stunnel4 dropbear

# --- LOCK PROTECTION ---
chattr +i /etc/nginx/conf.d/xray.conf
chattr +i /usr/local/etc/xray/config.json
chattr +i /etc/stunnel/stunnel.conf

echo "-------------------------------------------------------"
echo "  AKSI SELESAI! SEMUA PORT AKTIF & TERKUNCI KING!      "
echo "  Nginx  : 80, 443, 2082                               "
echo "  Stunnel: 444                                         "
echo "  SSH WS : 80, 443, 2082 (Via Nginx)                   "
echo "-------------------------------------------------------"
