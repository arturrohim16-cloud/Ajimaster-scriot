#!/bin/bash
# =========================================
# Quick Setup | Script Setup Manager
# Edition : Ultimate Masterpiece V3.0
# Author  : AJI STORE PREMIUM
# =========================================

# // Export Color
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# // Root Checking
if [ "${EUID}" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Jalankan sebagai root!"
    exit 1
fi

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}          INSTALLER XRAY CORE - AJI STORE          ${NC}"
echo -e "${BLUE}             (FULL AUTOMATIC RUNNING)              ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# // 1. Input Domain
echo -e "[ ${GREEN}INFO${NC} ] Konfigurasi Domain..."
read -p "   Masukkan Domain: " domain

if [[ -z "$domain" ]]; then
    echo -e "[ ${RED}ERROR${NC} ] Domain kosong! Batalkan..."
    exit 1
fi

# Simpan domain & Siapkan Folder
mkdir -p /etc/xray
mkdir -p /home/vps/public_html
echo "$domain" > /etc/xray/domain

# // 2. Update & Dependencies
echo -e "[ ${GREEN}INFO${NC} ] Menginstall paket pendukung..."
apt update -y
apt install curl socat xz-utils wget apt-transport-https gnupg netcat cron chrony unzip nginx jq -y

# // 3. Setting Time & Firewall
timedatectl set-timezone Asia/Jakarta
systemctl enable chrony && systemctl restart chrony
# Buka port standar agar tidak terblokir firewall sendiri
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT

# // 4. Install Xray Core
echo -e "[ ${GREEN}INFO${NC} ] Mengunduh Xray Core Terbaru..."
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
wget -q -O xray.zip "https://github.com/XTLS/Xray-core/releases/download/v$latest_version/xray-linux-64.zip"
unzip -o xray.zip -d /usr/local/bin/
chmod +x /usr/local/bin/xray
rm -f xray.zip

# // 5. SSL Generation (Auto-Logic)
echo -e "[ ${GREEN}INFO${NC} ] Memulai pembuatan SSL (Otomatis)..."
systemctl stop nginx
rm -rf /root/.acme.sh
curl https://get.acme.sh | sh
alias acme.sh=~/.acme.sh/acme.sh

# Daftarkan Akun SSL
~/.acme.sh/acme.sh --register-account -m aji@gmail.com --server letsencrypt

# Coba Let's Encrypt, jika 429 (limit) langsung loncat ke ZeroSSL
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue -d "${domain}" --standalone --keylength ec-256 --force

if [ $? -ne 0 ]; then
    echo -e "[ ${YELLOW}WARNING${NC} ] Let's Encrypt Limit! Berpindah ke ZeroSSL..."
    ~/.acme.sh/acme.sh --set-default-ca --server zerossl
    ~/.acme.sh/acme.sh --issue -d "${domain}" --standalone --keylength ec-256 --force
fi

# Install Cert ke direktori Xray
~/.acme.sh/acme.sh --install-cert -d "${domain}" --ecc \
--fullchain-file /etc/xray/xray.crt \
--key-file /etc/xray/xray.key
chown -R www-data:www-data /etc/xray

# // 6. Configuration Ports & UUID
vless=$((RANDOM + 10000))
vmess=$((RANDOM + 11000))
trojan=$((RANDOM + 12000))
vlessgrpc=$((RANDOM + 13000))
uuid=$(cat /proc/sys/kernel/random/uuid)
# // 8. Generate Nginx Config (The Shield & Connector)
echo -e "[ ${GREEN}INFO${NC} ] Menyusun konfigurasi Nginx (xray.conf)..."
cat > /etc/nginx/conf.d/xray.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2 reuseport;
    listen [::]:443 ssl http2 reuseport;
    server_name $domain;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    root /home/vps/public_html;

    # Vless WebSocket
    location /vless {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$vless;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Vmess WebSocket
    location /vmess {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$vmess;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Trojan WebSocket
    location /trojan-ws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$trojanws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Shadowsocks WebSocket
    location /ss-ws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$ssws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # gRPC Paths (Vless, Vmess, Trojan)
    location ^~ /vless-grpc {
        proxy_redirect off;
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_pass grpc://127.0.0.1:$vlessgrpc;
    }

    location ^~ /vmess-grpc {
        proxy_redirect off;
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_pass grpc://127.0.0.1:$vmessgrpc;
    }

    location ^~ /trojan-grpc {
        proxy_redirect off;
        grpc_set_header X-Real-IP \$remote_addr;
        grpc_pass grpc://127.0.0.1:$trojangrpc;
    }
}
EOF
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

#config.json
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service By AJI STORE PREMIUM
Documentation=https://github.com/xtls/xray-core
After=network.target nss-lookup.target

[Service]
User=www-data
Group=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartSec=3s
# Menaikkan limit file agar sanggup menampung ribuan user sekaligus
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
# // 11. Finalizing
systemctl daemon-reload
systemctl enable xray nginx
systemctl restart xray nginx
# // 10. AUTO-RUN & VERIFICATION (BAGIAN PALING PENTING)
echo -e "[ ${GREEN}INFO${NC} ] Mengaktifkan semua layanan secara otomatis..."
systemctl daemon-reload
systemctl enable nginx xray
systemctl restart nginx xray

# Cek Status
status_nginx=$(systemctl is-active nginx)
status_xray=$(systemctl is-active xray)

clear
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "         INSTALLASI SELESAI - AJI STORE PREMIUM     "
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Domain   : $domain"
echo -e "  UUID     : $uuid"
echo -e "  Nginx    : $status_nginx"
echo -e "  Xray     : $status_xray"
echo -e "  Vless WS : $vless"
echo -e "  Vmess WS : $vmess"
echo -e "  Trojan WS: $trojan"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " Semua layanan telah berjalan otomatis (RUNNING) "
