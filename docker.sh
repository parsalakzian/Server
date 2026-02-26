#!/bin/bash

# آدرس پراکسی تو
PROXY="socks5h://omixy2.ominicorp.com:49508"

echo "Starting Docker installation with proxy..."

# ۱. نصب پیش‌نیازها با استفاده از پراکسی موقت برای apt و curl
sudo apt update -o Acquire::http::Proxy="http://127.0.0.1:1" # یه ترفند برای نادیده گرفتن تنظیمات اشتباه احتمالی
sudo apt install -y -o Acquire::socks::proxy="$PROXY" ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings

# ۲. دانلود کلید GPG با استفاده از پراکسی در curl
sudo curl -x "$PROXY" -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# ۳. اضافه کردن ریپازیتوری
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# ۴. آپدیت و نصب داکر (استفاده از پراکسی برای مخازن داکر)
sudo apt update -o Acquire::socks::proxy="$PROXY"
sudo apt install -y -o Acquire::socks::proxy="$PROXY" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ۵. تنظیم دائمی پراکسی برای Daemon داکر (جهت Pull کردن از داکر هاب)
sudo mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="HTTP_PROXY=$PROXY"
Environment="HTTPS_PROXY=$PROXY"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

# ۶. اعمال تغییرات و ری‌استارت
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Done! Docker is installed and configured with proxy."
