cat > /usr/bin/limit-ip << 'END'
#!/bin/bash

# Folder Log
LOG_FILE="/var/log/ssh-limit.log"

while true; do
    if [ -f "/etc/ssh/limit-ip" ]; then
        # Membaca database limit (Format: user limit)
        while read -r user limit; do
            [[ -z "$user" || -z "$limit" ]] && continue

            # --- LOGIKA 1: Deteksi User Aktif via 'who' ---
            # 'who' hanya mencatat user yang sudah melewati fase otentikasi (Lolos Password)
            current_sessions=$(who | grep -w "$user" | awk '{print $1}' | wc -l)

            # --- LOGIKA 2: Deteksi IP Unik via netstat ---
            # Kita pastikan berapa IP berbeda yang sedang terkoneksi ke port SSH (22, 143, 109, 443)
            # Ini sangat akurat untuk membedakan 1 orang (meski banyak proses) vs 2 orang
            unique_ips=$(netstat -anp | grep ESTABLISHED | grep sshd | grep -w "$user" | awk '{print $5}' | cut -d: -f1 | sort -u | wc -l)

            # Kita ambil angka tertinggi antara session atau IP unik
            actual_usage=$current_sessions
            if [ "$unique_ips" -gt "$current_sessions" ]; then
                actual_usage=$unique_ips
            fi

            # --- EKSEKUSI ---
            if [ "$actual_usage" -gt "$limit" ]; then
                # Hitung kelebihan
                excess=$((actual_usage - limit))
                
                # Ambil PID paling baru (Latest Login)
                # Kita hanya mengambil PID yang punya TTY (pts) agar tidak membunuh proses sistem
                pids_to_kill=$(ps -u "$user" -o pid,comm,args | grep sshd | grep -E "pts|notty" | awk '{print $1}' | tail -n "$excess")

                for pid in $pids_to_kill; do
                    if [ -n "$pid" ]; then
                        # Jeda 10 detik agar tidak "kaget" (permintaan user)
                        # Dijalankan di background agar loop tidak macet
                        (
                            sleep 10
                            # Cek ulang setelah 10 detik, apakah masih melampaui limit?
                            recheck_usage=$(who | grep -w "$user" | wc -l)
                            if [ "$recheck_usage" -gt "$limit" ]; then
                                kill -9 "$pid" >/dev/null 2>&1
                                echo "$(date) : [AUTO-KILL] User $user ($actual_usage/$limit) PID $pid dimatikan." >> "$LOG_FILE"
                            fi
                        ) &
                    fi
                done
            fi
        done < /etc/ssh/limit-ip
    fi
    # Interval pengecekan (5-10 detik agar tidak membebani CPU)
    sleep 7
done
END

chmod +x /usr/bin/limit-ip
