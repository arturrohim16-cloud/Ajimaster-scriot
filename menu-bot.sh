cat > /usr/bin/menu-bot << 'END'
#!/bin/bash

# --- WARNA TERANG ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- FILE CONFIG ---
CONF="/etc/root/bot.conf"

# --- FUNGSI CEK STATUS ---
function get_status() {
    if [ -f "$CONF" ]; then
        source "$CONF"
        if [[ -n "$TOKEN" && -n "$CHATID" ]]; then
            echo -e "${GREEN}ONLINE / ACTIVE${NC}"
        else
            echo -e "${RED}OFF / DISABLED${NC}"
        fi
    else
        echo -e "${RED}NOT CONFIGURED${NC}"
    fi
}

# --- MENU UTAMA ---
while true; do
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "         ${WHITE}PANEL NOTIFIKASI BOT TELEGRAM${NC}          "
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Status Bot : $(get_status)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}[1]${NC} ${GREEN}Input / Update Token Bot${NC}"
    echo -e "  ${WHITE}[2]${NC} ${YELLOW}Restart Bot System (Refresh)${NC}"
    echo -e "  ${WHITE}[3]${NC} ${RED}Matikan Bot (Temporary Off)${NC}"
    echo -e "  ${WHITE}[4]${NC} ${RED}Hapus Total Config Bot${NC}"
    echo -e "  ${WHITE}[x]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "  Pilih Menu [1-4 atau x] : " opt

    case $opt in
        1)
            echo -e "\n${YELLOW}Petunjuk: Ambil Token di @BotFather & ID di @userinfobot${NC}"
            read -p "  Masukkan Token : " bot_token
            read -p "  Masukkan Chat ID: " chat_id
            if [[ -z "$bot_token" || -z "$chat_id" ]]; then
                echo -e "\n${RED}Gagal: Data tidak boleh kosong!${NC}"
            else
                mkdir -p /etc/root
                echo "TOKEN=\"$bot_token\"" > "$CONF"
                echo "CHATID=\"$chat_id\"" >> "$CONF"
                echo -e "\n${GREEN}Sukses! Bot aktif dan siap mengirim notifikasi.${NC}"
            fi
            sleep 2
            ;;
        2)
            echo -e "\n${YELLOW}Restarting Bot System...${NC}"
            # Me-restart service pendukung agar koneksi bot segar kembali
            systemctl restart nginx >/dev/null 2>&1
            systemctl restart xray >/dev/null 2>&1
            echo -e "${GREEN}Sistem bot telah di-refresh!${NC}"
            sleep 2
            ;;
        3)
            if [ -f "$CONF" ]; then
                # Menonaktifkan bot dengan mengosongkan variabel tanpa hapus file
                sed -i 's/TOKEN=.*/TOKEN=""/g' "$CONF"
                sed -i 's/CHATID=.*/CHATID=""/g' "$CONF"
                echo -e "\n${RED}Bot dinonaktifkan sementara.${NC}"
            else
                echo -e "\n${YELLOW}Config tidak ditemukan.${NC}"
            fi
            sleep 2
            ;;
        4)
            if [ -f "$CONF" ]; then
                rm -f "$CONF"
                echo -e "\n${RED}Seluruh konfigurasi bot telah DIHAPUS TOTAL!${NC}"
            else
                echo -e "\n${YELLOW}Config memang sudah tidak ada.${NC}"
            fi
            sleep 2
            ;;
        x)
            menu
            exit
            ;;
        *)
            echo -e "${RED}Pilihan tidak ada!${NC}"
            sleep 1
            ;;
    esac
done
END
chmod +x /usr/bin/menu-bot
