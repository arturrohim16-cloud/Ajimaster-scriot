#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium By Gemini AI
# ==========================================

# 1. Update & Instal Komponen Dasar
apt update -y
apt install nginx xray jq python3 python3-pip curl wget screen -y

# 2. Buat Direktori yang Dibutuhkan
mkdir -p /etc/xray
mkdir -p /usr/local/etc/xray
mkdir -p /var/log/xray

# 3. Download & Pasang Mesin Xray (Config)
cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vmess-ws", "port": 443, "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "security": "tls",
        "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }] },
        "wsSettings": { "path": "/vmess" }
      }
    },
    {
      "tag": "vless-ws", "port": 443, "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "security": "tls",
        "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }] },
        "wsSettings": { "path": "/vless" }
      }
    },
    {
      "tag": "trojan-ws", "port": 443, "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "security": "tls",
        "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }] },
        "wsSettings": { "path": "/trojan" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
EOF

# 4. Pasang Mesin Websocket SSH (Port 2082)
cat <<EOF > /usr/local/bin/ws-python
import socket, threading
def proxy(client, address):
    try:
        data = client.recv(1024).decode()
        if 'Upgrade: websocket' in data:
            client.send(b'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n')
            target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target.connect(('127.0.0.1', 143))
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
chmod +x /usr/local/bin/ws-python

# 5. Jalankan WS-Python di Background
screen -dmS ws python3 /usr/local/bin/ws-python

# 6. Download File MENU (Script Mewah Kita)
# GANTI LINK DI BAWAH INI DENGAN LINK RAW MENU GITHUB KAMU
wget --header="Authorization: token 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" -O /usr/bin/menu "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/main/menu" && chmod +x /usr/bin/menu

# 7. Restart & Enable Semua Service
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl restart nginx

echo "Pemasangan Selesai! Ketik 'menu' untuk memulai."

