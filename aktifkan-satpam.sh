#!/bin/bash

# ==========================================
# SCRIPT PENJAGA LIMIT IP (ANTI-SHARING)
# ==========================================
cat <<EOF > /usr/local/bin/user-limit
#!/bin/bash
while true; do
  for user in \$(cut -d: -f1 /etc/passwd); do
    # Ambil angka setelah 'MaxIP:'
    limit=\$(grep -w "\$user" /etc/passwd | cut -d: -f5 | grep -oP 'MaxIP:\K[0-9]+')
    if [[ -n \$limit && \$limit -ne 0 ]]; then
      current=\$(ps -u \$user | grep sshd | wc -l)
      if [[ \$current -gt \$limit ]]; then
        pkill -u \$user
      fi
    fi
  done
  sleep 15
done
EOF

# ==========================================
# SCRIPT PENJAGA LIMIT GB (QUOTA WATCHDOG)
# ==========================================
cat <<EOF > /usr/local/bin/quota-limit
#!/bin/bash
while true; do
  for user in \$(cut -d: -f1 /etc/passwd); do
    # Ambil angka setelah 'MaxGB:'
    limit_gb=\$(grep -w "\$user" /etc/passwd | cut -d: -f5 | grep -oP 'MaxGB:\K[0-9]+')
    if [[ -n \$limit_gb && \$limit_gb -ne 0 ]]; then
      # Cek trafik (Estimasi sederhana per user)
      usage=\$(vnstat -u -i eth0 --oneline | cut -d';' -f10 | sed 's/ GiB//;s/ MiB//')
      # Jika pemakaian lebih besar dari limit, kunci user
      if [ "\$(echo "\$usage > \$limit_gb" | bc -l)" == "1" ]; then
        pkill -u \$user
        usermod -L \$user
      fi
    fi
  done
  sleep 60
done
EOF

# Memberikan izin eksekusi
chmod +x /usr/local/bin/user-limit
chmod +x /usr/local/bin/quota-limit

# Menjalankan di latar belakang menggunakan Screen
pkill -f user-limit
pkill -f quota-limit
screen -dmS satpam-ip /usr/local/bin/user-limit
screen -dmS satpam-gb /usr/local/bin/quota-limit

echo "OTAK LIMIT IP & GB BERHASIL DIAKTIFKAN, KING!"

