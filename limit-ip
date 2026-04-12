cat > /usr/bin/limit-ip << 'END'
#!/bin/bash

# --- FUNGSI AUTO INSTALL SERVICE (Hanya jalan jika service belum ada) ---
if [ ! -f "/etc/systemd/system/limit-ip.service" ]; then
    echo "Memasang Service Limit IP..."
    cat > /etc/systemd/system/limit-ip.service << EOF
[Unit]
Description=Limit IP Service By Akhir Zaman
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/bash /usr/bin/limit-ip
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable limit-ip
    systemctl start limit-ip
    echo "Service Berhasil Dipasang dan Dijalankan!"
fi

# --- LOGIKA UTAMA MONITORING ---
echo "Monitoring Limit IP Sedang Berjalan..."
while true; do
    # Memastikan file database ada agar tidak error
    if [ -f "/etc/ssh/limit-ip" ]; then
        cat /etc/ssh/limit-ip | while read user limit; do
            # Menghitung jumlah login sshd per user
            current=$(ps -u $user | grep sshd | wc -l)
            
            # Jika login melebihi limit
            if [ $current -gt $limit ]; then
                pkill -u $user
                echo "$(date) : User $user melanggar limit IP ($current/$limit) - Diputuskan!" >> /var/log/ssh-limit.log
            fi
        done
    fi
    sleep 5
done
END

# Memberikan izin eksekusi
chmod +x /usr/bin/limit-ip

# Jalankan sekali untuk memancing instalasi service-nya
/usr/bin/limit-ip &
