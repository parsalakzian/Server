#!/bin/bash

REPO_URL="https://github.com/parsalakzian/OminiServer.git"
PROJECT_NAME="OminiServer"
TARGET_DIR="/home/$PROJECT_NAME"
DEPLOY_SCRIPT="$TARGET_DIR/run.sh"
SERVICE_NAME="ominiserver-run"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
TIMER_PATH="/etc/systemd/system/$SERVICE_NAME.timer"

if [ ! -d "$TARGET_DIR" ]; then
    echo "📦 Project not found. Cloning..."
    git clone "$REPO_URL" "$TARGET_DIR"
    chmod +x "$DEPLOY_SCRIPT"
    
    echo "🚀 Running docker-compose after first clone..."
    cd "$TARGET_DIR" || exit 1
    docker-compose up --build --force-recreate -d
else
    echo "✅ Project already exists."
fi

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

changed=0
update_if_changed "$SERVICE_PATH" "$SERVICE_CONTENT" && changed=1
update_if_changed "$TIMER_PATH" "$TIMER_CONTENT" && changed=1

if [ "$changed" -eq 1 ]; then
    echo "🔄 Reloading and restarting systemd units..."
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME.timer"
    sudo systemctl restart "$SERVICE_NAME.timer"
else
    echo "✅ Service and timer already up to date."
fi

echo "🎉 Setup complete!"
