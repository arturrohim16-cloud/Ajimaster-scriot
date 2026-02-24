#!/bin/bash
# Script Auto SSL & Config X-Ray by Ajimaster

DOMAIN="aji.izz-store.my.id"
mkdir -p /etc/xray

# 1. Install Acme.sh (Alat SSL)
apt install socat curl -y
curl https://get.acme.sh | sh
source ~/.bashrc
~/.acme.sh/acme.sh --register-account -m admin@$DOMAIN

# 2. Stop layanan yang pakai port 80/443 agar tidak bentrok saat proses SSL
systemctl stop xray
pkill python3

# 3. Request Sertifikat SSL (Standalone Mode)
~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone -k ec-256

# 4. Install Sertifikat ke folder X-Ray
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
--fullchain-file /etc/xray/xray.crt \
--key-file /etc/xray/xray.key --ecc

# 5. Pasang Config X-Ray Premium (Vmess, Vless, Trojan)
cat <<EOF > /usr/local/etc/xray/config.json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "wsSettings": {"path": "/vless"}
      }
    },
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess"}
      }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# 6. Simpan domain ke sistem agar menu 'add_vmess' bisa baca
echo "$DOMAIN" > /etc/xray/domain

# 7. Nyalakan ulang semua mesin
systemctl restart xray
systemctl enable xray
screen -dmS ws-python python3 /usr/local/bin/ws-python 80 # Jika Mas pakai python ws

echo "SSL BERHASIL DIPASANG UNTUK DOMAIN: $DOMAIN"
echo "Silahkan buat akun baru di menu dan tes konek TLS 443!"
