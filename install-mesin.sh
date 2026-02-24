#!/bin/bash
# Installer Mesin All-in-One: Xray, Nginx, SSL
# Domain: aji.izz-store.my.id

DOMAIN="aji.izz-store.my.id"
IP=$(wget -qO- ipinfo.io/ip)

# 1. Update & Install Tools Dasar
apt update && apt install -y nginx socat curl tar uuid-runtime

# 2. Install Xray Core Terbaru
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

# 3. Setup Sertifikat SSL (Acme.sh)
pkill nginx
pkill python3
mkdir -p /etc/xray
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m admin@$DOMAIN
~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone -k ec-256
~/.acme.sh/acme.sh --install-cert -d $DOMAIN --fullchain-file /etc/xray/xray.crt --key-file /etc/xray/xray.key --ecc

# 4. Config Nginx (Sebagai Pintu Utama Port 443 & 80)
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location /trojan {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
EOF

# 5. Config Xray (Menerima operan dari Nginx)
cat <<EOF > /usr/local/etc/xray/config.json
{
    "inbounds": [
        {
            "port": 10001, "listen": "127.0.0.1", "protocol": "vmess",
            "settings": {"clients": []}, "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}}
        },
        {
            "port": 10002, "listen": "127.0.0.1", "protocol": "vless",
            "settings": {"clients": [], "decryption": "none"}, "streamSettings": {"network": "ws", "wsSettings": {"path": "/vless"}}
        },
        {
            "port": 10003, "listen": "127.0.0.1", "protocol": "trojan",
            "settings": {"clients": []}, "streamSettings": {"network": "ws", "wsSettings": {"path": "/trojan"}}
        }
    ],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

# 6. Izin Akses & Restart
chown -R www-data:www-data /etc/xray
chmod +x /usr/local/bin/xray
systemctl restart nginx
systemctl restart xray
echo "$DOMAIN" > /etc/xray/domain

echo "INSTALASI BERHASIL! SEMUA PORT SUDAH TERKONEKSI KE NGINX."
