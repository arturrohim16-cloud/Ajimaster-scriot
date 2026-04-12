cat > /usr/bin/limit-vmess << 'END'
#!/bin/bash
# Script pemantau login Vmess berdasarkan IP unik

while true; do
    if [ -f "/etc/vmess/limit-ip" ]; then
        cat /etc/vmess/limit-ip | while read user limit; do
            # Menghitung jumlah IP unik yang sedang konek ke akun vmess tersebut
            # Menggunakan log akses xray
            current=$(tail -n 500 /var/log/xray/access.log | grep "$user" | awk '{print $3}' | cut -d: -f1 | sort | uniq | wc -l)
            
            if [ $current -gt $limit ]; then
                # Jika melebihi limit, kita hapus user sementara dari config atau restart service
                # Untuk Vmess, cara paling umum adalah menendang via API atau memblokir IP tersebut di firewall
                echo "$(date) : User $user over limit IP ($current/$limit)" >> /var/log/vmess-limit.log
                
                # Opsi: Anda bisa menambahkan perintah untuk kick user di sini
            fi
        done
    fi
    sleep 10
done
END
chmod +x /usr/bin/limit-vmess

