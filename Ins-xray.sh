#!/bin/bash
# =========================================
# OMNI-SYNC MAX LEVEL - AJI STORE PREMIUM
# Anti-Crash, Auto-SSL, Full-Sync Architecture
# =========================================

# // Color & Export
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# // 1. PRE-INSTALLATION & CLEANING
echo -e "${BLUE}[ 1/5 ]${NC} Membersihkan port dan proses lama..."
systemctl stop nginx xray apache2 2>/dev/null
fuser -k 80/tcp 443/tcp 2>/dev/null

# // 2. CENTRALIZED VARIABLES (Otak Script)
domain=$(cat /root/domain 2>/dev/null || cat /etc/xray/domain)
uuid=$(cat /etc/xray/uuid 2>/dev/null || cat /proc/sys/kernel/random/uuid)
# Port Internal (Paling Aman di range ini)
v_vless="10001"; v_vmess="11000"; v_trojan="12000"

if [[ -z "$domain" ]]; then echo -e "${RED}EROR: Domain tidak ditemukan!${NC}"; exit 1; fi
echo "$uuid" > /etc/xray/uuid

# // 3. SMART SSL GENERATION (MAX LEVEL LOGIC)
echo -e "${BLUE}[ 2/5 ]${NC} Memproses SSL (Let's Encrypt / ZeroSSL / Self-Signed)..."
mkdir -p /etc/xray

# Install acme.sh jika belum ada
[[ ! -f /root/.acme.sh/acme.sh ]] && curl https://get.acme.sh | sh -s email=admin@$domain >/dev/null 2>&1

# Coba Let's Encrypt secara diam-diam
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
~/.acme.sh/acme.sh --issue -d "$domain" --standalone --keylength ec-256 --force >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
    echo -e "${YELLOW}[ INFO ]${NC} Let's Encrypt limit, mencoba ZeroSSL..."
    ~/.acme.sh/acme.sh --set-default-ca --server zerossl >/dev/null 2>&1
    ~/.acme.sh/acme.sh --issue -d "$domain" --standalone --keylength ec-256 --force >/dev/null 2>&1
fi

# Install atau Fallback ke Self-Signed jika gagal total
if [[ -f /root/.acme.sh/${domain}_ecc/fullchain.cer ]]; then
    ~/.acme.sh/acme.sh --install-cert -d "$domain" --ecc \
    --fullchain-file /etc/xray/xray.crt --key-file /etc/xray/xray.key >/dev/null 2>&1
    echo -e "${GREEN}[ OKEY ]${NC} SSL Asli Berhasil Dipasang."
else
    echo -e "${YELLOW}[ INFO ]${NC} DNS Belum Siap, Membuat SSL Darurat (Self-Signed)..."
    openssl req -x509 -nodes -days 365 -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout /etc/xray/xray.key -out /etc/xray/xray.crt \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=AJI-STORE/CN=$domain" >/dev/null 2>&1
fi

# // 4. XRAY CONFIGURATION (PURE JSON - NO TYPO)
echo -e "${BLUE}[ 3/5 ]${NC} Menyusun Xray config.json..."
cat > /etc/xray/config.json <<EOF
{
  "log" : {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
      {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
   {
     "listen": "127.0.0.1",
     "port": "$vless",
     "protocol": "vless",
      "settings": {
          "decryption":"none",
            "clients": [
               {
                 "id": "${uuid}"                 
#vless
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vless"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "$vmess",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmess
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vmess"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "$worryfree",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmessworry
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/worryfree"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "$kuotahabis",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmesskuota
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/kuota-habis"
          }
        }
     },
    {
      "listen": "127.0.0.1",
      "port": "$trojanws",
      "protocol": "trojan",
      "settings": {
          "decryption":"none",		
           "clients": [
              {
                 "password": "${uuid}"
#trojanws
              }
          ],
         "udp": true
       },
       "streamSettings":{
           "network": "ws",
           "wsSettings": {
               "path": "/trojan-ws"
            }
         }
     },
    {
         "listen": "127.0.0.1",
        "port": "$ssws",
        "protocol": "shadowsocks",
        "settings": {
           "clients": [
           {
           "method": "aes-128-gcm",
          "password": "${uuid}"
#ssws
           }
          ],
          "network": "tcp,udp"
       },
       "streamSettings":{
          "network": "ws",
             "wsSettings": {
               "path": "/ss-ws"
           }
        }
     },	
      {
        "listen": "127.0.0.1",
        "port": "$vlessgrpc",
        "protocol": "vless",
        "settings": {
         "decryption":"none",
           "clients": [
             {
               "id": "${uuid}"
#vlessgrpc
             }
          ]
       },
          "streamSettings":{
             "network": "grpc",
             "grpcSettings": {
                "serviceName": "vless-grpc"
           }
        }
     },
     {
      "listen": "127.0.0.1",
      "port": "$vmessgrpc",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmessgrpc
             }
          ]
       },
       "streamSettings":{
         "network": "grpc",
            "grpcSettings": {
                "serviceName": "vmess-grpc"
          }
        }
     },
     {
        "listen": "127.0.0.1",
        "port": "$trojangrpc",
        "protocol": "trojan",
        "settings": {
          "decryption":"none",
             "clients": [
               {
                 "password": "${uuid}"
#trojangrpc
               }
           ]
        },
         "streamSettings":{
         "network": "grpc",
           "grpcSettings": {
               "serviceName": "trojan-grpc"
         }
      }
   },
   {
    "listen": "127.0.0.1",
    "port": "$ssgrpc",
    "protocol": "shadowsocks",
    "settings": {
        "clients": [
          {
             "method": "aes-128-gcm",
             "password": "${uuid}"
#ssgrpc
           }
         ],
           "network": "tcp,udp"
      },
    "streamSettings":{
     "network": "grpc",
        "grpcSettings": {
           "serviceName": "ss-grpc"
          }
       }
    }	
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
EOF

# // 5. NGINX CONFIGURATION (ADVANCED SYNC)
echo -e "${BLUE}[ 4/5 ]${NC} Menyusun Nginx Reverse Proxy..."
rm -f /etc/nginx/conf.d/xray.conf
cat > /etc/nginx/conf.d/xray.conf <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name _;
    
    # SSL Certificates
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Modern SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # WebSocket VLESS
    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket VMESS  
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # WebSocket Trojan
    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # gRPC VLESS
    location ^~ /vless-grpc {
        grpc_pass grpc://127.0.0.1:8083;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # gRPC VMESS
    location ^~ /vmess-grpc {
        grpc_pass grpc://127.0.0.1:8084;
        grpc_set_header X-Real-IP $remote_addr;
    }
    
    # Fallback Static
    location / {
        root /home/vps/public_html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
}
EOF
# // FINALIZING
echo -e "${BLUE}[ 5/5 ]${NC} Menghidupkan Semua Layanan..."
mkdir -p /var/log/xray
chown -R www-data:www-data /etc/xray /var/log/xray
rm -f /etc/nginx/sites-enabled/default

systemctl daemon-reload
systemctl enable nginx xray
systemctl restart xray nginx

echo -e "---"
echo -e "${GREEN}FIX SELESAI! STATUS:${NC}"
echo -e "UUID   : $uuid"
echo -e "DOMAIN : $domain"
echo -e "---"
systemctl status nginx xray --no-pager | grep "Active"
