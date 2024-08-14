#!/bin/bash

# Baca konfigurasi
source /etc/kangpantau/config.conf
source /etc/kangpantau/cameralist.conf

# Fungsi untuk merekam stream RTSP dengan overlap
record_stream() {
  local camera_name=$1
  local rtsp_url=$2
    # Loop untuk terus merekam dengan overlap
    while true; do
      # Dapatkan tanggal saat ini dalam format YYYY-MM-DD
      local current_date=$(date +%Y-%m-%d)
      # Buat direktori output berdasarkan nama kamera dan tanggal
      local output_path="${OUTPUT_PATH}${camera_name}/${current_date}/"
      if [ ! -d "$output_path" ]; then
        # Jika belum ada, buat direktori
        mkdir -p "$output_path"
      fi
      # Dapatkan timestamp saat ini
      local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
      # Nama file output untuk segmen
      local output_file="${output_path}segment_${timestamp}.mp4"

      # Rekam segmen penuh selama 15 detik
      ffmpeg -rtsp_transport tcp -t $DURATION -i $rtsp_url -c:v copy -c:a aac $output_file &

      # Tunggu 12 detik sebelum memulai segmen berikutnya
      sleep $((DURATION - OVERLAP))
    done
}

# Fungsi untuk menghapus file yang lebih lama dari RETENTION_DAYS
clean_old_files() {
  find $OUTPUT_PATH -mindepth 2 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +
}

# Baca setiap baris dari cameralist.conf dan jalankan perekaman
while IFS='=' read -r camera_name rtsp_url; do
  record_stream $camera_name $rtsp_url &
done < /etc/kangpantau/cameralist.conf

# Jalankan fungsi untuk menghapus file lama setiap hari
while true; do
  clean_old_files
  sleep 3600 # 24 jam
done &

# Tunggu semua proses selesai
wait

