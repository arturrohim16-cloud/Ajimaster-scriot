#!/bin/bash
TOKEN="8226263150:AAFdiVuQeEshxOpSvema_F6fDwbyFcfNWnw"
CHATID="6577966386"
URL="https://api.telegram.org/bot$TOKEN"

# Ambil IP VPS otomatis
DOMAIN=$(cat /etc/xray/domain)
IP=$(wget -qO- ipinfo.io/ip)

while true; do
    # Ambil pesan terakhir
    UPDATES=$(curl -s "$URL/getUpdates?offset=-1&limit=1")
    MESSAGE=$(echo $UPDATES | grep -oP '(?<="text":")[^"]*')
    USER_ID=$(echo $UPDATES | grep -oP '(?<="from":{"id":)[^,]*')
    NAME=$(echo $UPDATES | grep -oP '(?<="first_name":")[^"]*')
    
    if [[ -n "$MESSAGE" ]]; then
        case $MESSAGE in
        "/start")
            TEXT="Halo $NAME! Selamat Datang di *Ajimaster Premium Bot* 🚀%0A%0ASilakan pilih Layanan Trial (1 Hari):%0A1. /trial_vmess%0A2. /trial_vless%0A3. /trial_trojan%0A4. /trial_ssh%0A%0AAtau Hubungi Admin: @arturrohim16"
            curl -s "$URL/sendMessage?chat_id=$USER_ID&text=$TEXT&parse_mode=Markdown"
            ;;

        "/trial_vmess")
            user="TRIAL-VMESS-$USER_ID"
            uuid=$(cat /proc/sys/kernel/random/uuid)
            exp=$(date -d "1 days" +"%Y-%m-%d")
            # Logika Add User Vmess (Menambah ke config Xray)
            cat > /etc/xray/vmess-$user.json <<EOF
{ "id": "$uuid", "alterId": 0, "email": "$user" }
EOF
            # Format Config Vmess (Standard v2rayNG)
            config_raw="{ \"v\": \"2\", \"ps\": \"AJI-$user\", \"add\": \"$DOMAIN\", \"port\": \"443\", \"id\": \"$uuid\", \"aid\": \"0\", \"net\": \"ws\", \"path\": \"/vmess\", \"type\": \"none\", \"host\": \"$DOMAIN\", \"tls\": \"tls\" }"
            vmess_link="vmess://$(echo -n $config_raw | base64 -w 0)"
            
            TEXT="✅ *TRIAL VMESS BERHASIL* %0A%0AHost: \`$DOMAIN\`%0APort: \`443\`%0AUUID: \`$uuid\`%0AExp: $exp%0A%0A*Copy Config:*%0A\`$vmess_link\`"
            curl -s "$URL/sendMessage?chat_id=$USER_ID&text=$TEXT&parse_mode=Markdown"
            systemctl restart xray
            ;;

        "/trial_vless")
            user="TRIAL-VLESS-$USER_ID"
            uuid=$(cat /proc/sys/kernel/random/uuid)
            vless_link="vless://$uuid@$DOMAIN:443?path=/vless&security=tls&encryption=none&type=ws#AJI-$user"
            
            TEXT="✅ *TRIAL VLESS BERHASIL* %0A%0AHost: \`$DOMAIN\`%0APort: \`443\`%0AUUID: \`$uuid\`%0A%0A*Copy Config:*%0A\`$vless_link\`"
            curl -s "$URL/sendMessage?chat_id=$USER_ID&text=$TEXT&parse_mode=Markdown"
            systemctl restart xray
            ;;

        "/trial_ssh")
            user="trial$(base64 /dev/urandom | tr -d '/+' | head -c 4)"
            pass="1"
            useradd -e $(date -d "1 days" +"%Y-%m-%d") -s /bin/false -M $user
            echo "$user:$pass" | chpasswd
            
            TEXT="✅ *TRIAL SSH BERHASIL* %0A%0AHost: \`$IP\`%0APort: \`22, 80, 443\`%0AUser: \`$user\`%0APass: \`$pass\`%0AExp: 1 Hari"
            curl -s "$URL/sendMessage?chat_id=$USER_ID&text=$TEXT&parse_mode=Markdown"
            ;;

        *)
            # Abaikan pesan lain
            ;;
        esac
        
        # Notif ke Owner (Mas Aji)
        curl -s "$URL/sendMessage?chat_id=$CHATID&text=🔔 *Notif Bot:* User $NAME ($USER_ID) baru saja membuat akun trial $MESSAGE"
    fi
    sleep 2
done

