cat > /usr/bin/limit-ip <<  END 
#!/bin/bash

while true; do
    if [ -f "/etc/ssh/limit-ip" ]; then
        while read -r user limit; do
            [[ -z "$user" || -z "$limit" ]] && continue

            # LOGIKA PINTAR: 
            # Kita hanya menghitung baris di 'who' atau 'users' yang benar-benar aktif.
            # 'who' hanya mencatat user yang sudah berhasil melewati tahap autentikasi.
            current_count=$(who | grep -w "$user" | wc -l)

            if [ "$current_count" -gt "$limit" ]; then
                # Hitung berapa koneksi yang harus ditendang
                excess=$((current_count - limit))
                
                # Ambil PID sshd milik user yang PALING BARU (paling bawah di ps)
                # Kita mencari proses sshd yang ada string '@pts' atau '@notty' (ciri khas user login)
                all_pids=$(ps -u "$user" -o pid,comm,args | grep sshd | grep -E "pts|notty" | awk '{print $1}')
                to_kill=$(echo "$all_pids" | tail -n "$excess")

                for pid in $to_kill; do
                    if [ -n "$pid" ]; then
                        # Berikan delay 10 detik sebelum benar-benar di-kill (sesuai permintaan)
                        # Kita jalankan di background agar tidak menghentikan loop user lain
                        (
                            sleep 10
                            # Cek lagi, jika masih melebihi limit, baru kill
                            recheck=$(who | grep -w "$user" | wc -l)
                            if [ "$recheck" -gt "$limit" ]; then
                                kill -9 "$pid" >/dev/null 2>&1
                                echo "$(date) : User $user melampaui limit ($recheck/$limit). PID $pid dimatikan setelah 10 detik." >> /var/log/ssh-limit.log
                            fi
                        ) &
                    fi
                done
            fi
        done < /etc/ssh/limit-ip
    fi
    # Loop pengecekan setiap 5 detik agar responsif tapi tidak berat
    sleep 5
done
END

chmod +x /usr/bin/limit-ip
systemctl restart limit-ip
