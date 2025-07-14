#!/bin/bash

REPO_URL="git@github.com:parsalakzian/OminiServer.git"
PROJECT_NAME="OminiServer"
TARGET_DIR="/home/$PROJECT_NAME"
DEPLOY_SCRIPT="$TARGET_DIR/run.sh"
SERVICE_NAME="ominiserver-run"

# Clone the project if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "📦 Project not found. Cloning..."
    git clone "$REPO_URL" "$TARGET_DIR"
    chmod +x "$DEPLOY_SCRIPT"
else
    echo "✅ Project already cloned."
fi

# Create systemd service and timer
echo "🔧 Creating systemd service and timer..."

# Create service unit
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=OminiServer Auto-Deploy Service

[Service]
Type=oneshot
ExecStart=$DEPLOY_SCRIPT
WorkingDirectory=$TARGET_DIR
EOF

# Create timer unit
sudo tee /etc/systemd/system/$SERVICE_NAME.timer > /dev/null <<EOF
[Unit]
Description=Run OminiServer Deploy Script every 2 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
Unit=$SERVICE_NAME.service

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable --now $SERVICE_NAME.timer

echo "✅ Service and timer have been successfully created and started!"
