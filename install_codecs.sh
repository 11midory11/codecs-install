#!/usr/bin/env bash
#
# Полностью автоматический скрипт установки всех мультимедийных кодеков на Pop!_OS 22.04 LTS x86_64
#
# Что делает:
# 1) Останавливает PackageKit, чтобы APT не блокировал операции.
# 2) Принимает лицензионное соглашение ttf-mscorefonts-installer.
# 3) Подключает репозитории multiverse и restricted.
# 4) Устанавливает ubuntu-restricted-extras (MP3/AAC/H.264 + шрифты Microsoft).
# 5) Ставит GStreamer-плагины (base/good/bad/ugly/libav).
# 6) Устанавливает FFmpeg.
# 7) Подключает libdvd-pkg → libdvdcss2 (для коммерческих DVD).
# 8) Ставит дополнительные кодеки (AV1, VP9, MP3, AAC, FLAC и др.).
# 9) Устанавливает GUI-плееры VLC и MPV.
# 10) Перезапускает PackageKit.
#
# Использование:
#   chmod +x install_codecs.sh
#   sudo ./install_codecs.sh
#
set -euo pipefail

echor(){ echo -e "\e[1;32m[INFO]\e[0m $*"; }
echow(){ echo -e "\e[1;33m[WARN]\e[0m $*"; }
echof(){ echo -e "\e[1;31m[ERROR]\e[0m $*"; }

# 0. Проверяем права
if [ "$(id -u)" -ne 0 ]; then
  echof "Скрипт нужно запускать с правами root (через sudo)."
  exit 1
fi

echor "=== 0) Останавливаем PackageKit (чтобы не блокировал apt) ==="
if systemctl is-active --quiet packagekit; then
  systemctl stop packagekit
  echor "PackageKit остановлен."
else
  echor "PackageKit уже не запущен."
fi

export DEBIAN_FRONTEND=noninteractive

# 1. Принимаем EULA Microsoft Fonts
echor "=== 1) Принимаем лицензионное соглашение ttf-mscorefonts-installer ==="
apt update
apt install -y debconf-utils
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
  | debconf-set-selections

# 2. Репозитории multiverse и restricted
echor "=== 2) Подключаем репозитории multiverse и restricted ==="
add-apt-repository -y multiverse
add-apt-repository -y restricted
apt update

# 3. ubuntu-restricted-extras
echor "=== 3) Устанавливаем ubuntu-restricted-extras ==="
apt install -y ubuntu-restricted-extras

# 4. GStreamer-плагины
echor "=== 4) Устанавливаем GStreamer-плагины ==="
apt install -y \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly

# 5. FFmpeg
echor "=== 5) Устанавливаем FFmpeg ==="
apt install -y ffmpeg

# 6. libdvd-pkg → libdvdcss2
echor "=== 6) Устанавливаем поддержку коммерческих DVD ==="
echo "libdvd-pkg libdvd-pkg/install_css boolean true" | debconf-set-selections
apt install -y libdvd-pkg
dpkg-reconfigure -f noninteractive libdvd-pkg

# 7. Дополнительные кодеки (AV1, VP9, MP3, AAC, FLAC и др.)
echor "=== 7) Устанавливаем дополнительные кодеки ==="
apt install -y \
  libavcodec-extra \
  libdav1d5 \
  libvpx7 \
  libopus0 \
  libvorbis0a \
  libmp3lame0 \
  liba52-0.7.4 \
  libopenh264-6

# 8. (Опционально) Библиотеки для Blu-ray (без AACS/DRM)
echor "=== 8) Устанавливаем библиотеки для Blu-ray ==="
apt install -y libaacs0 libbdplus0 libbluray-bdj

# 9. GUI-плееры VLC и MPV
echor "=== 9) Устанавливаем VLC и MPV ==="
apt install -y vlc mpv

# 10. Перезапускаем PackageKit
echor "=== 10) Перезапускаем PackageKit ==="
systemctl start packagekit && echor "PackageKit запущен." || echow "Не удалось запустить PackageKit."

echor "=== УСТАНОВКА КОДЕКОВ ЗАВЕРШЕНА ==="
echor "Рекомендуется перезагрузить систему: sudo reboot"

