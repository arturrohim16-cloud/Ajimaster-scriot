cat > /usr/bin/limit-ip << 'END'
#!/bin/bash

while true; do
    if [ -f "/etc/ssh/limit-ip" ]; then
        # Membaca file limit-ip
        while read -r user limit; do
            [[ -z "$user" || -z "$limit" ]] && continue

            # Hanya hitung koneksi SSH yang sudah ESTABLISHED (Benar-benar login)
            # Ini mencegah proses login/handshake ikut terhitung dan terbunuh
            current_pids=$(ps -u "$user" -o pid,comm,state | grep sshd | grep -v "grep" | awk '{print $1}')
            current_count=$(echo "$current_pids" | wc -w)

            if [ "$current_count" -gt "$limit" ]; then
                # Hitung jumlah kelebihan
                excess=$((current_count - limit))
                
                # Ambil PID yang paling baru login (paling bawah) untuk dimatikan
                # Kita berikan jeda sedikit agar tidak terlalu agresif
                to_kill=$(echo "$current_pids" | tail -n "$excess")

                for pid in $to_kill; do
                    # Cek sekali lagi apakah PID masih ada sebelum kill
                    if ps -p "$pid" > /dev/null; then
                        kill -9 "$pid"
                        echo "$(date) : User $user melampaui limit ($current_count/$limit). PID $pid dimatikan." >> /var/log/ssh-limit.log
                    fi
                done
            fi
        done < /etc/ssh/limit-ip
    fi
    # Naikkan sleep menjadi 10-15 detik agar server tidak terlalu berat 
    # dan memberi waktu user untuk menstabilkan koneksi
    sleep 10
done
END

chmod +x /usr/bin/limit-ip
systemctl restart limit-ip
