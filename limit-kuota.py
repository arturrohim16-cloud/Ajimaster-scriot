cat > /usr/bin/limit-quota << 'END'
#!/bin/bash

# --- AUTO INSTALL SERVICE ---
if [ ! -f "/etc/systemd/system/limit-quota.service" ]; then
    cat > /etc/systemd/system/limit-quota.service << EOF
[Unit]
Description=Limit Quota Service By Akhir Zaman
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/bash /usr/bin/limit-quota
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable limit-quota
    systemctl start limit-quota
fi

# --- LOGIKA MONITORING KUOTA ---
while true; do
    if [ -f "/etc/ssh/limit-quota" ]; then
        cat /etc/ssh/limit-quota | while read user limit_gb; do
            # Mengambil data pemakaian dalam GB (Contoh menggunakan vnstat)
            # Jika Anda belum install vnstat, script ini akan stand-by
            if command -v vnstat > /dev/null; then
                usage=$(vnstat -u $user --json | jq '.interfaces[].traffic.total' 2>/dev/null) # Ini butuh jq & vnstat
                # Konversi ke GB (Sederhananya kita asumsikan pengecekan byte)
                
                # JIKA PEMAKAIAN > LIMIT
                # if [ $usage -gt $limit_gb ]; then
                #    pkill -u $user
                #    passwd -l $user # Mengunci akun agar tidak bisa login lagi
                #    echo "$(date) : User $user kuota habis ($limit_gb GB) - Locked!" >> /var/log/ssh-quota.log
                # fi
            fi
        done
    fi
    sleep 60 # Cek setiap 1 menit agar tidak berat di CPU
done
END

chmod +x /usr/bin/limit-quota
/usr/bin/limit-quota &
