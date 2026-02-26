#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium By Gemini AI
# ==========================================

# --- KONFIGURASI GITHUB ---
TOKEN="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"
REPO_URL="https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/main"

# 1. Update & Instal Komponen Dasar
echo -e "Update & Install Software Dasar..."
apt update -y
apt install nginx xray jq python3 python3-pip curl wget screen -y

# 2. Buat Direktori Sistem
mkdir -p /etc/xray
mkdir -p /usr/local/etc/xray
mkdir -p /var/log/xray

# 3. Pasang Mesin Xray (Config Utama)
echo -e "Memasang Konfigurasi Xray..."
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
echo -e "Memasang Websocket Python..."
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
screen -dmS ws python3 /usr/local/bin/ws-python

# 5. Download File MENU Utama (Dashboard Mewah)
echo -e "Mengambil File Menu dari GitHub..."
wget --header="Authorization: token $TOKEN" -O /usr/bin/menu "$REPO_URL/menu"
chmod +x /usr/bin/menu

# 6. Download File Pendukung (Trial, Cek Online, dll)
# Catatan: Pastikan file-file ini ada di GitHub kamu di dalam folder Scriptku/
echo -e "Mengambil File Pendukung..."
FILES=("trial_ssh" "trial_vmess" "trial_vless" "trial_trojan" "cek_online" "exp_cleaner" "del_user")

for FILE in "${FILES[@]}"; do
    wget --header="Authorization: token $TOKEN" -O /usr/bin/$FILE "$REPO_URL/Scriptku/$FILE"
    chmod +x /usr/bin/$FILE
done

# 7. Restart & Enable Semua Service
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl restart nginx

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   INSTALLASI SELESAI DENGAN SEMPURNA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Ketik 'menu' untuk membuka dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
