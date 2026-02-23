#!/bin/bash

# 1. Update & Install Tools Dasar
apt update -y
apt install python3 stunnel4 net-tools screen -y

# 2. Buat Mesin Websocket (Port 80)
cat <<EOF > /usr/bin/ws-python
import socket, threading
def proxy(client_socket):
    try:
        data = client_socket.recv(1024)
        if b"Upgrade: websocket" in data:
            client_socket.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target.connect(("127.0.0.1", 22))
            def forward(src, dst):
                try:
                    while True:
                        buf = src.recv(4096)
                        if not buf: break
                        dst.send(buf)
                except: pass
            threading.Thread(target=forward, args=(client_socket, target)).start()
            forward(target, client_socket)
    except: pass
    finally: client_socket.close()
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("0.0.0.0", 80))
server.listen(100)
while True:
    client, addr = server.accept()
    threading.Thread(target=proxy, args=(client,)).start()
EOF
chmod +x /usr/bin/ws-python

# 3. Buat Mesin Stunnel (Port 443)
cat <<EOF > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel4.pid
[ssh]
accept = 443
connect = 127.0.0.1:22
EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

# 4. Buat Mesin UDP Custom (Port 1-65535) - Versi Simple
wget -q -O /usr/bin/udp-custom "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/main/udp-custom"
chmod +x /usr/bin/udp-custom

# 5. Jalankan Semua Mesin
pkill python3
screen -dmS ws-python python3 /usr/bin/ws-python
systemctl restart stunnel4
screen -dmS udp-custom /usr/bin/udp-custom server

# 6. Buka Firewall
ufw disable
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 1:65535 -j ACCEPT

echo "SEMUA PORT (80, 443, 1-65535) BERHASIL DIAKTIFKAN!"

