#!/bin/bash
# =========================================
# Quick Setup | SSH & OVPN Manager
# Edition : Stable Edition V1.0 - AJI SYSTEM
# =========================================

# [ 1. INITIAL SETUP ]
export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'
clear

# Warna & Banner (Sesuai kode kamu)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Check Root
if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}Error: Please Run As Root!${NC}"
    exit 1
fi

# [ 2. INSTALL DEPENDENCIES ]
echo -e "[ ${GREEN}INFO${NC} ] Installing Dependencies..."
apt update -y
apt install -y nginx xray jq python3 python3-pip curl wget screen stunnel4 dropbear socat build-essential libssl-dev zlib1g-dev make

# Link Python3 ke Python (Agar script lama tetap jalan)
ln -sf /usr/bin/python3 /usr/bin/python

# [ 3. SETUP WEBSOCKET SERVICES ]
# Menghindari kesalahan kutip pada wget
echo -e "[ ${GREEN}INFO${NC} ] Downloading Websocket Scripts..."

# WS Dropbear
wget -q -O /usr/local/bin/ws-dropbear "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-drobear.py"
chmod +x /usr/local/bin/ws-dropbear

# WS OpenVPN
wget -q -O /usr/local/bin/ws-ovpn "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-ovpn.py"
chmod +x /usr/local/bin/ws-ovpn

# WS TLS
wget -q -O /usr/local/bin/ws-tls "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-tls.py"
chmod +x /usr/local/bin/ws-tls

#ws nontls
wget -q -0 /user/local/bin/ws-nontls "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-nontls.py"
chmod +x /user/local/bin/ws-nontls

#install srunel15
wget -q -0 /user/local/bin/stunel15 "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/stunel15.init"
chmod +x /user/local/bin/stunel15
# [ 4. REGISTER SYSTEMD SERVICES ]
# Service WS Dropbear (Port 8880)
cat > /etc/systemd/system/ws-dropbear.service << END
[Unit]
Description=SSH Websocket Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-dropbear 8880
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

# Service WS OpenVPN (Port 2086)
cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=Websocket OpenVPN Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-ovpn 2086
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

#service ws openvpn (port 443)
cat > /etc/systemd/systemd/ws-tls.service << END
[Unit]
Description=SSH Websocket Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-tls 443
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

#service ws openvpn (port 80)
cat > /etc/systemd/systemd/ws-nontls.service << END
[Unit]
Description=SSH Websocket service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-nontls 8880
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

#sevice stunel15
cat > /etc/systemd/systemd/stunel15.service << END
[Unit]
Description=Stunnel5 Service
After=network.target auditd.service
ConditionFileNotEmpty=/etc/stunnel5/stunnel5.conf

[Service]
Type=forking
ExecStart=/usr/local/lamvpn/stunnel5 /etc/stunnel5/stunnel5.conf
KillMode=process
Restart=on-failure
RestartSec=5
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
END

chmod +x /etc/init.d/stunnel5
chmod +x /usr/local/lamvpn/stunnel5
systemctl daemon-reload
systemctl enable stunnel5
systemctl start stunnel5
systemctl stop stunnel5
systemctl restart stunnel5

systemctl daemon-reload
systemctl enable ws-dropbear ws-ovpn
systemctl restart ws-dropbear ws-ovpn

systemctl daemon-reload
systemctl enable ws-tls ws-ovpn
systemctl restart ws-tls ws-ovpn

systemctl daemon-reload
systemctl enable ws-nontls ws-ovpn
systemctl restart ws-nontls ws ovpn
# [ 5. CONFIGURE SSH & DROPBEAR ]
echo -e "[ ${GREEN}INFO${NC} ] Configuring SSH & Dropbear..."
# SSH Port 22 & 2253
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
echo "Port 2253" >> /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart ssh

# Dropbear Port 109 & 143
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109"/g' /etc/default/dropbear
systemctl restart dropbear

# [ 6. INSTALL STUNNEL 5 ]
# (Logika instalasi source tetap dipertahankan namun dipastikan path-nya)
echo -e "[ ${GREEN}INFO${NC} ] Installing Stunnel 5..."
cd /root
wget -q "https://raw.githubusercontent.com/NevermoreSSH/Blueblue/main/stunnel5.zip"
unzip -o stunnel5.zip
cd stunnel
chmod +x configure
./configure && make && make install

# Config Stunnel5
mkdir -p /etc/stunnel5
cat > /etc/stunnel5/stunnel5.conf << END
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1

[dropbear]
accept = 447
connect = 127.0.0.1:109

[openssh]
accept = 777
connect = 127.0.0.1:22
END

# [ 7. OPTIMIZATION (BBR & BADVPN) ]
# Bagian BBR & Badvpn diletakkan sebelum selesai agar performa langsung naik
echo -e "[ ${GREEN}INFO${NC} ] Optimizing System (BBR & Badvpn)..."
modprobe tcp_bbr
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# [ 8. FINISHING ]
echo -e "[ ${GREEN}INFO${NC} ] Cleaning Up..."
apt autoremove -y
history -c
echo -e "${GREEN}SSH & Websocket Installation Finished!${NC}"
