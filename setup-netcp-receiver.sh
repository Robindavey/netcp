#!/usr/bin/env bash

set -e

# Resolve paths dynamically
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
PYTHON="$PROJECT_DIR/venv/bin/python"
SCRIPT="$PROJECT_DIR/receiverServer.py"
SERVICE_NAME="${PROJECT_NAME}-receiver"

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SYSTEMD_DIR/$SERVICE_NAME.service"

echo "Setting up NetCP receiver as a user service"
echo "Project: $PROJECT_NAME"
echo "Directory: $PROJECT_DIR"

# Sanity checks
if [[ ! -x "$PYTHON" ]]; then
    echo "❌ Python venv not found at $PYTHON"
    exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
    echo "❌ receiverServer.py not found in $PROJECT_DIR"
    exit 1
fi

# Create systemd user directory
mkdir -p "$SYSTEMD_DIR"

# Write service file
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=NetCP Receiver ($PROJECT_NAME)
After=network.target

[Service]
Type=simple
ExecStart=$PYTHON $SCRIPT
WorkingDirectory=$PROJECT_DIR
Restart=always
RestartSec=2
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=default.target
EOF

echo "✔ Service file written to:"
echo "  $SERVICE_FILE"

# Reload systemd user daemon
systemctl --user daemon-reexec
systemctl --user daemon-reload

# Start & enable service
systemctl --user start "$SERVICE_NAME"
systemctl --user enable "$SERVICE_NAME"

echo
echo "✅ NetCP receiver is running!"
echo
echo "Check status:"
echo "  systemctl --user status $SERVICE_NAME"
echo
echo "View logs:"
echo "  journalctl --user -u $SERVICE_NAME -f"
echo
echo "Optional (run once to keep service alive after logout):"
echo "  loginctl enable-linger \$USER"
