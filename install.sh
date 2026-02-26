#!/bin/bash
# ==========================================
# Auto-Installer VPN Premium Full Jantung
# ==========================================

# --- KONFIGURASI GITHUB ---
TOKEN="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"
REPO_URL="https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/main"

# 1. Update & Instal Semua Software (Lengkap)
echo -e "Update & Install Semua Software..."
apt update -y && apt upgrade -y
apt install nginx xray jq python3 python3-pip curl wget screen stunnel4 dropbear socat dbus-x11 -y

# 2. Buat Direktori & Sertifikat SSL Otomatis (Penting!)
mkdir -p /etc/xray
mkdir -p /usr/local/etc/xray
# Membuat Self-Signed SSL sementara agar Xray mau Start
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=ID/ST=Jawa/L=Jakarta/O=Aji/CN=izz-store.my.id" -keyout /etc/xray/xray.key -out /etc/xray/xray.crt

# 3. Pasang Mesin Xray (Port 443 & 80)
cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": { "access": "/var/log/xray/access.log", "error": "/var/log/xray/error.log", "loglevel": "warning" },
  "inbounds": [
    { "tag": "vmess-ws", "port": 443, "protocol": "vmess", "settings": { "clients": [] }, "streamSettings": { "network": "ws", "security": "tls", "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }] }, "wsSettings": { "path": "/vmess" } } },
    { "tag": "vless-ws", "port": 443, "protocol": "vless", "settings": { "clients": [], "decryption": "none" }, "streamSettings": { "network": "ws", "security": "tls", "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }] }, "wsSettings": { "path": "/vless" } } },
    { "tag": "trojan-ws", "port": 443, "protocol": "trojan", "settings": { "clients": [] }, "streamSettings": { "network": "ws", "security": "tls", "tlsSettings": { "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }] }, "wsSettings": { "path": "/trojan" } } }
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
EOF

# 4. Pasang Stunnel5 (SSH TLS Port 444)
echo -e "Konfigurasi Stunnel (Port 444)..."
cat <<EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel.pid
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[ssh]
accept = 444
connect = 127.0.0.1:143
EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

# 5. Pasang Dropbear (SSH Port 143 / 109)
echo -e "Konfigurasi Dropbear..."
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
echo 'DROPBEAR_EXTRA_ARGS="-p 109"' >> /etc/default/dropbear

# 6. Pasang BadVPN (Compile Otomatis)
echo -e "Sedang menginstal BadVPN UDP Gateway..."
apt install cmake make gcc -y
wget https://github.com/ambrop72/badvpn/archive/master.tar.gz
tar xf master.tar.gz
cd badvpn-master
mkdir build
cd build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
cd ../..
rm -rf badvpn-master master.tar.gz
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500

# 7. Pasang Websocket Python (Port 2082)
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

# 8. Download MENU & File Pendukung
wget --header="Authorization: token $TOKEN" -O /usr/bin/menu "$REPO_URL/menu"
chmod +x /usr/bin/menu

FILES=("trial_ssh" "trial_vmess" "trial_vless" "trial_trojan" "cek_online" "exp_cleaner" "del_user")
for FILE in "${FILES[@]}"; do
    wget --header="Authorization: token $TOKEN" -O /usr/bin/$FILE "$REPO_URL/Scriptku/$FILE"
    chmod +x /usr/bin/$FILE
done

# 9. Restart Semua Service
systemctl restart dropbear
systemctl restart stunnel4
systemctl restart xray
systemctl restart nginx

echo "Installasi Selesai! Semua Port (443, 80, 444, 2082, 143, 109, 7100) Telah Aktif."
