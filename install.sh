#!/bin/bash
# ==========================================
# Auto-Installer VPN AJI STORE - FINAL STABLE
# UPDATE: SUPPORT VMESS/VLESS/TROJAN PORT 80 & 443
# ==========================================

DOMAIN="aji.izz-store.my.id"
ID_VMESS="aaa5a187-d964-4fa9-b44b-21f1b6f820e7"
ID_VLESS_TR="d4dc3d49-c35c-4c35-9528-18e0c7e062ee"

# 1. Bersihkan sisa-sisa kegagalan (Wajib!)
systemctl stop nginx xray dropbear stunnel4 2>/dev/null
apt purge nginx xray -y && apt autoremove -y
rm -rf /etc/nginx/conf.d/*
rm -rf /etc/nginx/sites-enabled/*
rm -rf /usr/local/etc/xray/*
# 1. Hapus script yang error
rm -f /usr/local/bin/ws-dropbear

# 2. Tulis ulang script dengan versi Python 3 yang benar
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
            data = client.recv(1024) # Menerima header HTTP Upgrade
            client.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            _thread.start_new_thread(handle, (client, addr))
        except:
            client.close()

if __name__ == "__main__":
    main()
EOF

# 3. Beri izin eksekusi dan restart service
chmod +x /usr/local/bin/ws-dropbear
systemctl restart ws-dropbear


# 2. Instal ulang Core
apt update -y
apt install nginx jq curl wget stunnel4 dropbear socat -y
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 3. SSL Sultan (Biar Nginx Gak Merah)
mkdir -p /etc/xray
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=$DOMAIN" \
    -keyout /etc/xray/xray.key -out /etc/xray/xray.crt

# 4. Config Xray (Paling Stabil)
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

# 5. Config Nginx (Support Port 80 & 443 untuk SEMUA)
cat <<EOF > /etc/nginx/conf.d/xray.conf
server {
    listen 80;
    listen 2082;
    server_name $DOMAIN;

    # Jalur Vmess/Vless/Trojan di Port 80
    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }

    # Jalur SSH Websocket Port 80
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
    server_name $DOMAIN;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;

    # Jalur Vmess/Vless/Trojan di Port 443
    location /vmess { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /vless { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }
    location /trojan { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "Upgrade"; proxy_set_header Host \$host; }

    # Jalur SSH SSL
    location / {
        proxy_pass http://127.0.0.1:143;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

# 6. Dropbear & Stunnel (SSH 22, 143, 109, 444)
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
echo 'DROPBEAR_EXTRA_ARGS="-p 109 -p 22"' > /etc/default/dropbear

cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
[ssh]
accept = 444
connect = 127.0.0.1:143
EOF

# 7. Aktifkan & Restart
systemctl daemon-reload
systemctl enable xray nginx stunnel4 dropbear
systemctl restart xray nginx stunnel4 dropbear
systemctl restart nginx
systemctl enable nginx


echo "BOMM!! SEMUA HIJAU KING! PORT 80 & 443 READY!"
