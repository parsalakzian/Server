#!/bin/bash

# -----------------------------
# تنظیمات پروژه
# -----------------------------
REPO_URL="git@github.com:parsalakzian/OminiServer.git"
PROJECT_NAME="OminiServer"
TARGET_DIR="/home/$PROJECT_NAME"
DEPLOY_SCRIPT="$TARGET_DIR/run.sh"
BACKUP_SCRIPT="$TARGET_DIR/backup.sh"

# سرویس deploy
SERVICE_NAME="ominiserver-run"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
TIMER_PATH="/etc/systemd/system/$SERVICE_NAME.timer"

# سرویس backup
BACKUP_SERVICE_NAME="ominiserver-backup"
BACKUP_SERVICE_PATH="/etc/systemd/system/$BACKUP_SERVICE_NAME.service"
BACKUP_TIMER_PATH="/etc/systemd/system/$BACKUP_SERVICE_NAME.timer"

# -----------------------------
# کلون یا آپدیت پروژه
# -----------------------------
if [ ! -d "$TARGET_DIR" ]; then
    echo "📦 Project not found. Cloning..."
    git clone "$REPO_URL" "$TARGET_DIR"
    chmod +x "$DEPLOY_SCRIPT"
    chmod +x "$BACKUP_SCRIPT"
    
    echo "🚀 Running docker-compose after first clone..."
    cd "$TARGET_DIR" || exit 1
    docker-compose up --build --force-recreate -d
else
    echo "✅ Project already exists."
fi

# -----------------------------
# تعریف محتوا برای سرویس و تایمر deploy
# -----------------------------
SERVICE_CONTENT="[Unit]
Description=OminiServer Auto-Deploy Service

[Service]
Type=oneshot
User=root
ExecStart=$DEPLOY_SCRIPT
WorkingDirectory=$TARGET_DIR
"

TIMER_CONTENT="[Unit]
Description=Run OminiServer Deploy Script every 2 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
Unit=$SERVICE_NAME.service

[Install]
WantedBy=timers.target
"

# -----------------------------
# تعریف محتوا برای سرویس و تایمر backup
# -----------------------------
BACKUP_SERVICE_CONTENT="[Unit]
Description=OminiServer Backup Service

[Service]
Type=oneshot
User=root
ExecStart=$BACKUP_SCRIPT
WorkingDirectory=$TARGET_DIR
"

BACKUP_TIMER_CONTENT="[Unit]
Description=Run OminiServer Backup Script daily

[Timer]
OnCalendar=daily
Persistent=true
Unit=$BACKUP_SERVICE_NAME.service

[Install]
WantedBy=timers.target
"

# -----------------------------
# تابع آپدیت فایل‌ها
# -----------------------------
update_if_changed() {
    local path="$1"
    local content="$2"

    if [ ! -f "$path" ] || ! diff -q <(echo "$content") "$path" >/dev/null; then
        echo "🔁 Updating: $path"
        echo "$content" | sudo tee "$path" > /dev/null
        return 0  # تغییر داشت
    else
        echo "✅ No changes in: $path"
        return 1  # بدون تغییر
    fi
}

# -----------------------------
# نصب و فعال‌سازی سرویس deploy
# -----------------------------
changed=0
update_if_changed "$SERVICE_PATH" "$SERVICE_CONTENT" && changed=1
update_if_changed "$TIMER_PATH" "$TIMER_CONTENT" && changed=1

if [ "$changed" -eq 1 ]; then
    echo "🔄 Reloading and restarting deploy systemd units..."
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME.timer"
    sudo systemctl restart "$SERVICE_NAME.timer"
else
    echo "✅ Deploy service and timer already up to date."
fi

# -----------------------------
# نصب و فعال‌سازی سرویس backup
# -----------------------------
changed_backup=0
update_if_changed "$BACKUP_SERVICE_PATH" "$BACKUP_SERVICE_CONTENT" && changed_backup=1
update_if_changed "$BACKUP_TIMER_PATH" "$BACKUP_TIMER_CONTENT" && changed_backup=1

if [ "$changed_backup" -eq 1 ]; then
    echo "🔄 Reloading and restarting backup systemd units..."
    sudo systemctl daemon-reload
    sudo systemctl enable "$BACKUP_SERVICE_NAME.timer"
    sudo systemctl restart "$BACKUP_SERVICE_NAME.timer"
else
    echo "✅ Backup service and timer already up to date."
fi

echo "🎉 Setup complete!"
