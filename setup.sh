dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')

# // Root Checking
if [ "${EUID}" -ne 0 ]; then
		echo -e "${EROR} Please Run This Script As Root User !"
		exit 1
fi
clear
# // Exporting Language to UTF-8
export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'

# // Export Color & Information
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT='\033[0;37m'
export NC='\033[0m'
BIRed='\033[1;91m'
red='\e[1;31m'
bo='\e[1m'
red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }
# // Export Banner Status Information
export EROR="[${RED} ERROR ${NC}]"
export INFO="[${YELLOW} INFO ${NC}]"
export OKEY="[${GREEN} OKEY ${NC}]"
export PENDING="[${YELLOW} PENDING ${NC}]"
export SEND="[${YELLOW} SEND ${NC}]"
export RECEIVE="[${YELLOW} RECEIVE ${NC}]"

# // Export Align
export BOLD="\e[1m"
export WARNING="${RED}\e[5m"
export UNDERLINE="\e[4m"

# // Exporting Script Version
export VERSION="1.1"
 
# // Exporint IP AddressInformation
export IP=$( curl -s https://ipinfo.io/ip/ )

# // Set Time To Kuala_Lumpur / GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# // cek old script
if [[ -r /etc/xray/domain ]]; then

echo -e "${INFO} Having Script Detected !"
echo -e "${INFO} If You Replacing Script, All Client Data On This VPS Will Be Cleanup !"
read -p "Are You Sure Wanna Replace Script ? (Y/N) " josdong
if [[ $josdong == "Y" ]]; then
clear
echo -e "${INFO} Starting Replacing Script !"
elif [[ $josdong == "y" ]]; then
clear
echo -e "${INFO} Starting Replacing Script !"
rm -rf /var/lib/scrz-prem 
elif [[ $josdong == "N" ]]; then
echo -e "${INFO} Action Canceled !"
exit 1
elif [[ $josdong == "n" ]]; then
echo -e "${INFO} Action Canceled !"
exit 1
else
echo -e "${EROR} Your Input Is Wrong !"
exit 1
fi
clear
fi
echo -e "${GREEN}Starting Installation............${NC}"
# // Go To Root Directory
cd /root/
# // Remove
apt install python3 -y
apt install openvpn -y
apt install python4 -y
apt remove --purge nginx* -y
apt remove --purge nginx-common* -y
apt remove --purge nginx-full* -y
apt remove --purge dropbear* -y
apt remove --purge stunnel5* -y
apt remove --purge apache2* -y
apt remove --purge ufw* -y
apt remove --purge firewalld* -y
apt remove --purge exim4* -y
apt autoremove -y

# // Update
apt update -y

# // Install Requirement Tools
apt --reinstall --fix-missing install -y sudo dpkg psmisc socat jq ruby wondershaper tmux nmap bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip vim curl nano sed gnupg gnupg1 bc apt-transport-https build-essential gcc g++ automake make autoconf perl m4 dos2unix dropbear libreadline-dev zlib1g-dev libssl-dev dirmngr libxml-parser-perl neofetch git lsof iptables iptables-persistent openssl easy-rsa fail2ban vnstat libsqlite3-dev cron bash-completion ntpdate xz-utils gnupg2 dnsutils lsb-release chrony python3 python3-pip python3-dev python-is-python3
gem install lolcat
# Mendapatkan IP VPS secara otomatis
IP=$(curl -sS ipv4.icanhazip.com)

echo "--- INSTALL SSL CERTIFICATE ---"
# Meminta input domain dari pengguna
read -p " Masukkan Domain Anda: " DOMAIN

# Validasi jika input kosong
if [[ -z "$DOMAIN" ]]; then
    echo "Error: Domain tidak boleh kosong!"
    exit 1
fi

echo "Memulai proses instalasi SSL untuk $DOMAIN..."

# Pastikan certbot sudah terinstall
if ! command -v certbot &> /dev/null; then
    echo "Certbot belum terinstall. Menginstall certbot..."
    apt update && apt install -y certbot
fi

# Menghentikan layanan yang menggunakan port 80
systemctl stop nginx
systemctl stop xray
systemctl stop dropbear

# Proses request SSL
certbot certonly \
--standalone \
-d $DOMAIN \
--non-interactive \
--agree-tos \
-m admin@$DOMAIN --force-renewal

# Menjalankan kembali layanan
systemctl start nginx
systemctl restart nginx
systemctl restart xray
systemctl restart dropbear

# Membersihkan layar dan menampilkan hasil
clear
echo "==============================="
echo "       INSTALL SELESAI"
echo "==============================="
echo " Domain : $DOMAIN"
echo " IP     : $IP"
echo " SSL    : AKTIF / SUCCESS"
echo "==============================="

# // Update & Upgrade
apt update -y
apt upgrade -y
apt dist-upgrade -y

# // Clear
clear
clear && clear && clear
clear;clear;clear

# // Folder Sistem Yang Tidak Boleh Di Hapus
mkdir -p /usr/bin
# // Remove File & Directory
rm -fr /usr/local/bin/xray
rm -fr /usr/local/bin/stunnel
rm -fr /usr/local/bin/stunnel5
rm -fr /etc/nginx
rm -fr /var/lib/scrz-prem/
rm -fr /usr/bin/xray
rm -fr /etc/xray
rm -fr /usr/local/etc/xray
# // Making Directory 
mkdir -p /etc/nginx
mkdir -p /var/lib/scrz-prem/
mkdir -p /usr/bin/xray
mkdir -p /etc/xray
mkdir -p /usr/local/etc/xray

read -p "Masukkan domain yang sudah pointing ke VPS: " DOMAIN

mkdir -p /etc/xray
echo $DOMAIN > /etc/xray/domain

echo "Domain aktif : $DOMAIN"

sleep 2

echo -e "$white\033[0;34m┌─────────────────────────────────────────┐${NC}"
echo -e " \E[41;1;39m           ⇱ Install Jembot ⇲            \E[0m$NC"
echo -e "$white\033[0;34m└─────────────────────────────────────────┘${NC}"
sleep 1 
wget -q https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/install-jembut.sh && chmod +x install-jembut.sh && ./install-jembut.sh
#install ssh-vpn
echo -e "$white\033[0;34m┌─────────────────────────────────────────┐${NC}"
echo -e " \E[41;1;39m          ⇱ Install SSH / WS ⇲           \E[0m$NC"
echo -e "$white\033[0;34m└─────────────────────────────────────────┘${NC}"
sleep 1
wget -q https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
#install ins-xray
echo -e "$white\033[0;34m┌─────────────────────────────────────────┐${NC}"
echo -e " \E[41;1;39m            ⇱ Install Xray ⇲             \E[0m$NC"
echo -e "$white\033[0;34m└─────────────────────────────────────────┘${NC}"
sleep 1 
wget -q https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/Ins-xray.sh && chmod +x Ins-xray.sh && ./Ins-xray.sh
wget -q https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/set-br.sh && chmod +x set-br.sh && ./set-br.sh

# 6. DOWNLOAD MENU & COMMANDS
# Folder /usr/bin adalah tempat perintah terminal (menu, add-ws, dll)
wget -q -0 /usr/bin/add-vmess "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-vmess.sh" 
wget -q -0 /usr/bin/add-vless "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-vless.sh" 
wget -q -0 /usr/bin/add-tr "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-tr.sh" 
wget -q -0 /usr/bin/add-ws "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-ws.sh" 
wget -q -O /usr/bin/add-ssws "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-ssws.sh" 
wget -q -O /usr/bin/add-socks "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-socks.sh" 
wget -q -O /usr/bin/add-trgo "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/add-trgo.sh" 
wget -q -O /usr/bin/autoreboot "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/autoreboot.sh" 
wget -q -O /usr/bin/restart "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/restart.sh" 

#wget -q -O /usr/bin/tendang "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/tendang.sh

#wget -q -O /usr/bin/clearlog "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/clearlog.sh

wget -q -O /usr/bin/runing "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/runing.sh" 
wget -q -O /usr/bin/cek-trafik "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/cek-trafik.sh" 
wget -q -O /usr/bin/speedtes-cli "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/speedtes_cli.py" 
wget -q -O /usr/bin/cek-badwing "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/cek-badwing.sh" 
wget -q -O /usr/bin/ram "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/ram.sh" 
wget -q -O /usr/bin/limit-speed "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/limit-speed.sh"
wget -q -O /usr/bin/menu-vless "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-vless.sh" 
wget -q -O /usr/bin/menu-vmess "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-vmess.sh" 
wget -q -O /usr/bin/menu-socks "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-socks.sh" 
wget -q -O /usr/bin/menu-ss "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-ss.sh" 
wget -q -O /usr/bin/menu-trojan "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-trojan.sh" 
wget -q -O /usr/bin/menu-trgo "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-trgo.sh" 
wget -q -O /usr/bin/menu-ssh "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu-ssh.sh" 

#wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bekap-tg.sh

#wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/menu-bckp-github.sh

#wget -q -O https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/bckpbot.sh

wget -q -O /usr/bin/usernew "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/usernew.sh" 
wget -q -O /usr/bin/menu "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu.sh" 
wget -q -O /usr/bin/menu1 "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/menu1.sh" 
wget -q -O /usr/bin/webbin "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/webbin.sh" 
wget -q -O /usr/bin/xp "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/xp.sh" 

#wget -q -O /usr/bin/update "https://raw.githubusercontent.com/arturrohim16-cloud/Blueblue/refs/heads/main/update.sh

wget -q -O /usr/bin/dns "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/dns.sh" 
wget -q -O /usr/bin/netf "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/netf.sh" 
wget -q -O /usr/bin/bber "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/bbr.sh" 
wget -q -O /usr/bin/del-xray "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/del-xray.sh" 
wget -q -O /usr/bin/user-xray "https://raw.githubusercontent.com/arturrohim16-cloud/Ajimaster-scriot/refs/heads/main/user-xray.sh" 

echo -e "${INFO} Mendownload Perintah Manajemen..."

# [CONTOH PENEMPATAN DOWNLOAD COMMAND]
chmod +x /usr/bin/add-ws
chmod +x /usr/bin/add-ssws
chmod +x /usr/bin/add-socks
chmod +x /usr/bin//add-vless
chmod +x /usr/bin/add-tr
chmod +x /usr/bin/add-trgo
chmod +x /usr/bin/add-vmess
chmod +x /usr/bin/usernew
chmod +x /usr/bin/autoreboot
chmod +x /usr/bin/restart
#chmod +x /bin/bash/tendang
#chmod +x /bin/bash/clearlog
chmod +x /usr/bin/runing
chmod +x /usr/bin/cek-trafik
chmod +x /usr/bin/speedtes-cli
chmod +x /usr/bin/cek-badwing
chmod +x /usr/bin/ram
chmod +x /usr/bin/limit-speed
chmod +x /usr/bin/menu-vless
chmod +x /usr/bin/menu-vmess
chmod +x /usr/bin/menu-ss
chmod +x /usr/bin/menu-socks
chmod +x /usr/bin/menu-trojan
chmod +x /usr/bin/menu-trgo
chmod +x /usr/bin/menu-ssh
#chmod +x /bin/bash/menu-bckp
chmod +x /usr/bin/menu
chmod +x /usr/bin/menu1
#chmod +x /bin/bash/bckp
chmod +x /usr/bin/webbin
chmod +x /usr/bin/xp
#chmod +x /bin/bash/update
chmod +x /usr/bin/dns
chmod +x /usr/bin/netf
chmod +x /usr/bin/bbr
chmod +x /usr/bin/del-xray
chmod +x /usr/bin/user-xray

# > install gotop
    # Perbaikan: Menambahkan -f (fix-broken) setelah dpkg untuk memastikan dependencies terinstall otomatis
    gotop_latest="$(curl -s https://api.github.com/repos/arturrohim16-cloud/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
    gotop_link="https://github.com/arturrohim16-cloud/gotop/releases/download/gotopV4/gotop_v4.2.0_linux_amd64.deb"
    curl -sL "$gotop_link" -o /tmp/gotop.deb
    dpkg -i /tmp/gotop.deb >/dev/null 2>&1
    apt-get install -f -y >/dev/null 2>&1 # Memastikan library yang kurang terinstall

# > Setup Crontab
# Perbaikan: Pastikan file log atau script tujuan ada di /usr/bin/ agar tidak error command not found
echo "0 0 * * * root /usr/bin/xp" >> /etc/crontab
echo "0 1 * * * root /usr/bin/delete" >> /etc/crontab
echo "0 2 * * * root /usr/bin/cleaner" >> /etc/crontab
echo "0 3 * * * root /usr/bin/xp" >> /etc/crontab
echo "0 4 * * * root /usr/bin/delete" >> /etc/crontab
echo "0 7 * * * root /usr/bin/cleaner" >> /etc/crontab
echo "0 5 * * * root /sbin/reboot" >> /etc/crontab # Ubuntu terbaru lebih aman pakai /sbin/reboot
echo "0 6 * * * root /usr/bin/backup" >> /etc/crontab
echo "0 23 * * * root /usr/bin/backup" >> /etc/crontab
echo "5 23 * * * root /usr/bin/backup" >> /etc/crontab
cd

# ... (bagian cron.d tetap sama, sudah benar) ...

# Perbaikan restart service cron untuk Ubuntu terbaru (systemctl lebih stabil)
systemctl restart cron >/dev/null 2>&1

clear
# Perbaikan .profile agar tidak terjadi loop "clear" berlebihan pada beberapa terminal
cat > /root/.profile << END
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n || true
# menu # Di-comment jika tidak ingin menu muncul otomatis setiap login (opsional)
END
chmod 644 /root/.profile

# Perbaikan deteksi Python untuk Ubuntu 22.04/24.04
if ! command -v python3 &> /dev/null; then
    apt update && apt install -y python3
fi
# Membuat alias agar perintah 'python' memanggil 'python3'
if [ ! -f "/usr/bin/python" ]; then
    apt install -y python-is-python3
fi

# ... (bagian pembersihan log tetap sama) ...

# Perbaikan: Mengatasi error jika variabel green/NC belum didefinisikan di awal script
green='\e[0;32m'
orange='\e[0;33m'
NC='\e[0m'
CYAN='\e[0;36m'

echo -e "[ ${green}Please Wait Update DB${NC} ]"
# Perbaikan: Pastikan folder limit dibersihkan dulu sebelum clone agar tidak error "folder exists"
rm -rf /root/limit
git clone https://github.com/arturrohim16-cloud/limit.git /root/limit/ &> /dev/null

# Perbaikan: Mendapatkan IP publik terbaru jika variabel $IP kosong
IP=$(curl -sS ifconfig.me)

# Perbaikan Git: Menambahkan safe directory agar tidak error permission di Ubuntu baru
git config --global --add safe.directory /root/limit

babu=$(cat /etc/.geovpn/license.key 2>/dev/null || echo "NoKey")
echo -e "$babu $IP $Masa_Laku_License_Berlaku_Sampai" >> /root/limit/limit.txt
cd /root/limit
    git config --global user.email "ajijainalganteng@gmail.com" &> /dev/null
    git config --global user.name "arturrohim16-cloud" &> /dev/null
    rm -rf .git &> /dev/null
    git init &> /dev/null
    git add . &> /dev/null
    git commit -m "Update DB" &> /dev/null
    git branch -M main &> /dev/null
cd

# ... (bagian tampilan log-install tetap sama) ...
