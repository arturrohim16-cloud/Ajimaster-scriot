#!/bin/bash
# =========================================
# Quick Setup | Script Setup Manager
# Edition : Stable Edition V1.0
# Author  : AJI STORE PREMIUM
# =========================================

# // Export Color
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export NC='\033[0m'

# // Root Checking
if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Jalankan sebagai root!"
    exit 1
fi

clear
echo -e "${YELLOW}---------------------------------------------------${NC}"
echo -e "          INSTALLER XRAY CORE - AJI STORE          "
echo -e "${YELLOW}---------------------------------------------------${NC}"

# // 1. Input Domain
echo -e "[ ${GREEN}INFO${NC} ] Masukkan Domain Anda (Contoh: aji.izz-store.my.id)"
read -p "Domain: " domain

if [[ -z "$domain" ]]; then
    echo -e "[ ${RED}ERROR${NC} ] Domain tidak boleh kosong!"
    exit 1
fi

# Simpan domain
mkdir -p /etc/xray
echo "$domain" > /etc/xray/domain
echo "$domain" > /root/domain

# // 2. Update & Install Dependencies
echo -e "[ ${GREEN}INFO${NC} ] Menginstall paket pendukung..."
apt update -y
apt install curl socat xz-utils wget apt-transport-https gnupg netcat cron chrony unzip -y

# // 3. Setting Timezone
timedatectl set-timezone Asia/Jakarta
systemctl enable chrony && systemctl restart chrony

# // 4. Prepare Folders
mkdir -p /var/log/xray /home/vps/public_html
chown www-data:www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log /var/log/xray/error.log

# // 5. Install Xray Core (Latest)
echo -e "[ ${GREEN}INFO${NC} ] Mengunduh Xray Core Terbaru..."
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
wget -q -O xray.zip "https://github.com/XTLS/Xray-core/releases/download/v$latest_version/xray-linux-64.zip"
unzip -o xray.zip -d /usr/local/bin/
chmod +x /usr/local/bin/xray
rm -f xray.zip

# // 6. SSL Generation (Let's Encrypt / ZeroSSL)
echo -e "[ ${GREEN}INFO${NC} ] Memulai pembuatan sertifikat SSL..."
systemctl stop nginx
rm -rf /root/.acme.sh
curl https://get.acme.sh | sh
alias acme.sh=~/.acme.sh/acme.sh

# Coba Let's Encrypt dulu, jika gagal pindah ZeroSSL (Menghindari Rate Limit 429)
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m aji@gmail.com
~/.acme.sh/acme.sh --issue -d "${domain}" --standalone --keylength ec-256 --force

if [ $? -ne 0 ]; then
    echo -e "[ ${YELLOW}WARNING${NC} ] Let's Encrypt Gagal/Limit, Mencoba ZeroSSL..."
    ~/.acme.sh/acme.sh --set-default-ca --server zerossl
    ~/.acme.sh/acme.sh --issue -d "${domain}" --standalone --keylength ec-256 --force
fi

# Install Cert
~/.acme.sh/acme.sh --install-cert -d "${domain}" --ecc \
--fullchain-file /etc/xray/xray.crt \
--key-file /etc/xray/xray.key

chown -R www-data:www-data /etc/xray
chmod 644 /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

# // 7. Configuration Ports
vless=$((RANDOM + 10000))
vmess=$((RANDOM + 10000))
trojan=$((RANDOM + 10000))
vlessgrpc=$((RANDOM + 10001))
vmessgrpc=$((RANDOM + 10001))
uuid=$(cat /proc/sys/kernel/random/uuid)

# // Xray Config.json God-Mode Ultimate AJI STORE PREMIUM
cat > /etc/xray/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "api": {
    "services": [
      "HandlerService",
      "StatsService",
      "LoggerService"
    ],
    "tag": "api"
  },
  "stats": {},
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true,
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "bufferSize": 10240
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "dns": {
    "hosts": {
      "geosite:category-ads-all": "127.0.0.1",
      "domain:aji.store": "127.0.0.1"
    },
    "servers": [
      {
        "address": "1.1.1.1",
        "port": 53,
        "domains": ["geosite:google", "geosite:facebook", "geosite:youtube"]
      },
      {
        "address": "https://1.1.1.1/dns-query",
        "domains": ["geosite:geolocation-noncn"]
      },
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ],
    "queryStrategy": "UseIP",
    "tag": "dns_inbound"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1" },
      "tag": "api"
    },
    {
      "listen": "127.0.0.1",
      "port": $vless,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          { "id": "$uuid", "level": 0, "email": "vless-ws@ajistore" }
#vless-ws
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vless", "headers": { "Host": "$domain" } },
        "sockopt": { "tcpFastOpen": true }
      },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic", "fakedns"] },
      "tag": "vless-ws"
    },
    {
      "listen": "127.0.0.1",
      "port": $vmess,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "$uuid", "alterId": 0, "level": 0, "email": "vmess-ws@ajistore" }
#vmess-ws
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vmess", "headers": { "Host": "$domain" } },
        "sockopt": { "tcpFastOpen": true }
      },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic", "fakedns"] },
      "tag": "vmess-ws"
    },
    {
      "listen": "127.0.0.1",
      "port": $trojanws,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "$uuid", "level": 0, "email": "trojan-ws@ajistore" }
#trojan-ws
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/trojan-ws", "headers": { "Host": "$domain" } },
        "sockopt": { "tcpFastOpen": true }
      },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic", "fakedns"] },
      "tag": "trojan-ws"
    },
    {
      "listen": "127.0.0.1",
      "port": $vlessgrpc,
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          { "id": "$uuid", "level": 0, "email": "vless-grpc@ajistore" }
#vless-grpc
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "vless-grpc", "multiMode": true },
        "sockopt": { "tcpFastOpen": true }
      },
      "tag": "vless-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": $vmessgrpc,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "$uuid", "alterId": 0, "level": 0, "email": "vmess-grpc@ajistore" }
#vmess-grpc
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "vmess-grpc", "multiMode": true },
        "sockopt": { "tcpFastOpen": true }
      },
      "tag": "vmess-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": $trojangrpc,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "$uuid", "level": 0, "email": "trojan-grpc@ajistore" }
#trojan-grpc
        ]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "trojan-grpc", "multiMode": true },
        "sockopt": { "tcpFastOpen": true }
      },
      "tag": "trojan-grpc"
    },
    {
      "listen": "127.0.0.1",
      "port": $ssws,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "$uuid",
        "network": "tcp,udp",
        "level": 0,
        "email": "ss-ws@ajistore"
#ss-ws
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/ss-ws", "headers": { "Host": "$domain" } }
      },
      "tag": "shadowsocks-ws"
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": { "domainStrategy": "UseIP" }, "tag": "direct" },
    { "protocol": "blackhole", "settings": { "response": { "type": "http" } }, "tag": "blocked" },
    { "protocol": "dns", "tag": "dns-out" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      { "type": "field", "inboundTag": ["api"], "outboundTag": "api" },
      { "type": "field", "port": 53, "outboundTag": "dns-out" },
      { "type": "field", "protocol": ["bittorrent"], "outboundTag": "blocked" },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all",
          "geosite:category-ads-indonesia",
          "geosite:google-ads",
          "domain:ads.google.com",
          "domain:doubleclick.net",
          "domain:googlesyndication.com"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "ip": [
          "geoip:private",
          "geoip:cn",
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "127.0.0.0/8",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.168.0.0/16"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "domain": [
          "geosite:facebook",
          "geosite:instagram",
          "geosite:whatsapp",
          "geosite:telegram",
          "geosite:tiktok",
          "geosite:netflix",
          "geosite:disney"
        ],
        "outboundTag": "direct"
      }
    ]
  },
  "observatory": {
    "subjectSelector": ["vless-ws", "vmess-ws", "trojan-ws", "vless-grpc", "vmess-grpc"],
    "probeUrl": "https://www.google.com/generate_204",
    "probeInterval": "30s"
  },
  "burstObs": {
    "subjectSelector": ["vless-ws", "vmess-ws"],
    "pingConfig": { "destination": "1.1.1.1:53", "interval": "10s" }
  }
}
EOF
# // 10. Systemd Service
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service By AJI
After=network.target nss-lookup.target

[Service]
User=www-data
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# // 11. Finalizing
systemctl daemon-reload
systemctl enable xray nginx
systemctl restart xray nginx

echo -e "${GREEN}---------------------------------------------------${NC}"
echo -e "  INSTALLASI SELESAI! STATUS SERVICE: ON           "
echo -e "  Domain: $domain"
echo -e "  UUID  : $uuid"
echo -e "${GREEN}---------------------------------------------------${NC}"

