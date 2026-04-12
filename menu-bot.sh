cat > /usr/bin/menu-bot << 'END'
#!/bin/bash
clear
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "      PENGATURAN NOTIFIKASI BOT TELEGRAM  "
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e " Dapatkan Token di @BotFather"
echo -e " Dapatkan ID di @userinfobot"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p " 1. Masukkan Token Bot : " bot_token
read -p " 2. Masukkan Chat ID   : " chat_id

# Cek jika kosong
if [[ -z "$bot_token" || -z "$chat_id" ]]; then
    echo -e " Error: Token dan ID tidak boleh kosong!"
    sleep 2
    menu
    exit
fi

# Simpan ke config
mkdir -p /etc/root
echo "TOKEN=\"$bot_token\"" > /etc/root/bot.conf
echo "CHATID=\"$chat_id\"" >> /etc/root/bot.conf

echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e " Sukses! Notifikasi Bot Berhasil Diaktifkan."
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 2
menu
END
chmod +x /usr/bin/menu-bot

