cat > /usr/bin/limit-ip << 'END'
#!/bin/bash

while true; do
    if [ -f "/etc/ssh/limit-ip" ]; then
        cat /etc/ssh/limit-ip | while read user limit; do
            # Ambil semua PID (Process ID) sshd milik user, urutkan dari yang paling lama ke baru
            pids=$(ps -u $user -o pid,comm | grep sshd | awk '{print $1}')
            current=$(echo "$pids" | wc -w)

            if [ $current -gt $limit ]; then
                # Hitung berapa banyak yang harus dimatikan
                excess=$((current - limit))
                
                # Ambil PID yang paling baru (paling bawah/terakhir login)
                to_kill=$(echo "$pids" | tail -n $excess)

                for pid in $to_kill; do
                    kill -9 $pid
                    echo "$(date) : User $user melampaui limit ($current/$limit). PID $pid dimatikan." >> /var/log/ssh-limit.log
                done
            fi
        done
    fi
    sleep 5
done
END

# Jangan lupa restart service-nya agar perubahan aktif
systemctl restart limit-ip
