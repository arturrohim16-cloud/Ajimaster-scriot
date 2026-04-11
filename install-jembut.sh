#!/bin/bash

# // Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# // Export Banner Status
EROR="[${RED} EROR ${NC}]"
INFO="[${YELLOW} INFO ${NC}]"
OKEY="[${GREEN} OKEY ${NC}]"

# // Root Checking
if [ "${EUID}" -ne 0 ]; then
    echo -e "${EROR} Please Run This Script As Root User !"
    exit 1
fi

# // Simple OS Check
source /etc/os-release
if [[ $ID != "ubuntu" && $ID != "debian" ]]; then
    echo -e "${EROR} This script is only for Ubuntu/Debian!"
    exit 1
fi

clear
echo -e "${INFO} Memulai instalasi vnStat 2.6..."
sleep 2

# // Install Dependencies
echo -e "${INFO} Installing dependencies..."
apt update -y
apt install -y wget curl tar make gcc libsqlite3-dev pkg-config build-essential >/dev/null 2>&1

# // Exporting Network Interface
# Mengambil interface utama secara otomatis
NET=$(ip route show to default | awk '{print $5}')

# // Cleanup Old Version
systemctl stop vnstat >/dev/null 2>&1
apt purge vnstat -y >/dev/null 2>&1

# // Download and Compile
echo -e "${INFO} Downloading and Compiling vnStat 2.6..."
cd /root
wget -q https://github.com/NevermoreSSH/vnstat/releases/download/vnstat/vnstat-2.6.tar.gz
tar -zxvf vnstat-2.6.tar.gz >/dev/null 2>&1
cd vnstat-2.6

# Proses Compile
./configure --prefix=/usr --sysconfdir=/etc >/dev/null 2>&1
if [ $? -eq 0 ]; then
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
else
    echo -e "${EROR} Configure failed! Check dependencies."
    exit 1
fi

# // Configuration
cd /root
# Update interface di config
sed -i "s/Interface \"eth0\"/Interface \"$NET\"/g" /etc/vnstat.conf

# Buat user vnstat jika belum ada (mencegah error chown)
id -u vnstat &>/dev/null || useradd -r -s /bin/false vnstat

# Create database directory
mkdir -p /var/lib/vnstat
chown vnstat:vnstat /var/lib/vnstat -R

# // Initialize Database
sudo -u vnstat vnstat --create -i "$NET" >/dev/null 2>&1

# // Setup Systemd Service
# Karena install manual, kita buatkan file servicenya agar support systemctl
cat > /etc/systemd/system/vnstat.service << EOF
[Unit]
Description=vnStat network traffic monitor
After=network.target

[Service]
ExecStart=/usr/sbin/vnstatd -n
User=vnstat
Group=vnstat
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# // Start Service
systemctl daemon-reload
systemctl enable vnstat >/dev/null 2>&1
systemctl start vnstat >/dev/null 2>&1

# // Cleanup
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6

clear
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${OKEY} vnStat 2.6 Installed"
echo -e "  Interface : $NET"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 2
