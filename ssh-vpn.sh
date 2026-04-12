BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White
UWhite='\033[4;37m'       # White
On_IPurple='\033[0;105m'  #
On_IRed='\033[0;101m'
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White
NC='\e[0m'

# // Export Color & Information
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT='\033[0;37m'
export NC='\033[0m'

# // Export Banner Status Information
export EROR="[${RED} EROR ${NC}]"
export INFO="[${YELLOW} INFO ${NC}]"
export OKEY="[${GREEN} OKEY ${NC}]"
export PENDING="[${YELLOW} PENDING ${NC}]"
export SEND="[${YELLOW} SEND ${NC}]"
export RECEIVE="[${YELLOW} RECEIVE ${NC}]"

# // Export Align
export BOLD="\e[1m"
export WARNING="${RED}\e[5m"
export UNDERLINE="\e[4m"

# // Exporting URL Host
export Server_URL="raw.githubusercontent.com/NevermoreSSH/Blueblue/main/test"
export Server1_URL="raw.githubusercontent.com/NevermoreSSH/Blueblue/main/limit"
export Server_Port="443"
export Server_IP="underfined"
export Script_Mode="Stable"
export Auther=".geovpn"

# // Root Checking
if [ "${EUID}" -ne 0 ]; then
		echo -e "${EROR} Please Run This Script As Root User !"
		exit 1
fi

# // Exporting IP Address
export IP=$( curl -s https://ipinfo.io/ip/ )

# // Exporting Network Interface
export NETWORK_IFACE="$(ip route show to default | awk '{print $5}')"

# // Install Dependencies
echo -e "[ ${GREEN}INFO${NC} ] Installing Dependencies..."
apt update -y && apt upgrade -y
# Tambahkan python-is-python3 agar script lama tetap berjalan di Ubuntu baru
apt install nginx xray jq python3 python3-pip python-is-python3 curl wget screen stunnel4 dropbear socat dbus-x11 -y

export DEBIAN_FRONTEND=noninteractive
MYIP=$(curl -sS ifconfig.me);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

# detail nama perusahaan
country=ID
state=Indonesia
locality=Indonesia
organization=www.aixxy.codes
organizationalunit=www.aixxy.codes
commonname=www.aixxy.codes
email=admin@aixxy.com

# simple password minimal
wget -q -O /etc/pam.d/common-password "https://raw.githubusercontent.com/NevermoreSSH/Blueblue/main/password"
chmod +x /etc/pam.d/common-password

# go to root
cd
# Perbaikan: Memisahkan link download dan chmod
wget -O /usr/bin/ws-ovpn "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-ovpn.py"
chmod +x /usr/bin/ws-ovpn

cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=Websocket OpenVPN Service
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-ovpn 2086
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-ovpn
systemctl restart ws-ovpn

clear

# Getting websocket dropbear
wget -q -O /usr/bin/ws-dropbear "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-dropbear.py"
chmod +x /usr/bin/ws-dropbear

# Installing Service
cat > /etc/systemd/system/ws-dropbear.service << END
[Unit]
Description=Ssh Websocket By Akhir Zaman
Documentation=https://xnxx.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-dropbear 8880
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-dropbear
systemctl start ws-dropbear
systemctl restart ws-dropbear

clear

# Perbaikan link download
wget -q -O /usr/bin/ws-nontls "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-nontls.py"
chmod +x /usr/bin/ws-nontls

cat > /etc/systemd/system/ws-nontls.service << END
[Unit]
Description=Python Proxy Mod By geovpn
Documentation=https://t.me/geovpn
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-nontls 8880
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-nontls
systemctl start ws-nontls
systemctl restart ws-nontls

clear

# Perbaikan link download bot
wget -O /usr/bin/bot "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bot.sh"
chmod +x /usr/bin/bot

cat > /etc/systemd/system/telegram-bot.service << END
[Unit]
Description=Telegram Bot VPS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/bot
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable telegram-bot
systemctl restart telegram-bot

clear

# // 2. WEBSOCKET TLS (Port 443)
echo -e "[ ${GREEN}INFO${NC} ] Setup WS-TLS..."
wget -q -O /usr/bin/ws-tls "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-tls.py"
chmod +x /usr/bin/ws-tls

cat > /etc/systemd/system/ws-tls.service << END
[Unit]
Description=Python Proxy Mod By geovpn
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/bin/ws-tls 443
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-tls
systemctl start ws-tls
systemctl restart ws-tls

clear

# Getting websocket ssl stunnel
wget -O /usr/bin/ws-stunnel "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ws-stunnel.py"
chmod +x /usr/bin/ws-stunnel

# Installing Service Ovpn Websocket
cat > /etc/systemd/system/ws-stunnel.service << END
[Unit]
Description=Websocket SSL Service
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -O /usr/local/bin/ws-stunnel 443
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-stunnel
systemctl restart ws-stunnel

clear

# Setup RC-LOCAL untuk Ubuntu terbaru
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
exit 0
END

chmod +x /etc/rc.local
systemctl enable rc-local
systemctl start rc-local.service

# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# install badvpn
wget -q -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/NevermoreSSH/Blueblue/main/newudpgw"
chmod +x /usr/bin/badvpn-udpgw
# Menggunakan systemctl untuk mengelola badvpn lebih baik di Ubuntu baru, 
# tapi karena script ini menggunakan screen di rc.local, kita pertahankan alurnya:
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local

# SSH Config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh

# install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109"/g' /etc/default/dropbear
systemctl restart dropbear

# Install Stunnel5
cd /root/
wget -q "https://raw.githubusercontent.com/NevermoreSSH/Blueblue/main/stunnel5.zip"
unzip -o stunnel5.zip
cd /root/stunnel
chmod +x configure
./configure
make
make install
cd /root
rm -rf stunnel5.zip stunnel
#confik xray.conf
cat > /etc/nginx/conf.d/xray.conf << 'END'
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name _;
    root /var/www/html;
    index index.html;

    # Konfigurasi Path untuk V2RAY / XRAY
    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:24016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /trojan-ws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:34016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
END

# Config Stunnel5
mkdir -p /etc/stunnel5
cat > /etc/stunnel5/stunnel5.conf <<-END
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 447
connect = 127.0.0.1:109

[openssh]
accept = 777
connect = 127.0.0.1:22

[openvpn]
accept = 442
connect = 127.0.0.1:1194
END

# Service Stunnel5
cat > /etc/systemd/system/stunnel5.service << END
[Unit]
Description=Stunnel5 Service
After=syslog.target network-online.target

[Service]
ExecStart=/usr/local/bin/stunnel5 /etc/stunnel5/stunnel5.conf
Type=forking

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable stunnel5
systemctl restart stunnel5

#confik SSH-WS
# Membuat service untuk SSH-WS Port 80
cat > /etc/systemd/system/ws-stunnel.service << 'END'
[Unit]
Description=SSH Websocket Service
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/bin/ws-stunnel 80
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
END

# Membuat service untuk SSH-WS Port 8880 (Dropbear)
cat > /etc/systemd/system/ws-dropbear.service << 'END'
[Unit]
Description=SSH Websocket Dropbear Service
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/bin/ws-stunnel 8880
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
END
# Reload sistem service
systemctl daemon-reload

# Aktifkan dan jalankan Nginx
nginx -t && systemctl restart nginx
systemctl enable nginx

# Install BBR & Optimize
modprobe tcp_bbr
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p

# Aktifkan dan jalankan SSH-WS
systemctl enable ws-stunnel
systemctl enable ws-dropbear
systemctl restart ws-stunnel
systemctl restart ws-dropbear

history -c
echo "unset HISTFILE" >> /etc/profile

cd
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
yellow "SSH & OVPN install successfully"
sleep 2
clear
