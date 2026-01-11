#!/usr/bin/env bash
set -e
source scripts/common.sh

log "Updating netcp"

# If INSTALL_DIR equals the repository directory, skip copying to avoid
# "are the same file" errors when running update from the repo.
SRC_DIR="$PWD"
if [ "$(readlink -f "$SRC_DIR")" = "$(readlink -f "${INSTALL_DIR}")" ]; then
	log "Install directory is repository; skipping copy step"
else
	cp netcp.py recieverServer.py requirements.txt "${INSTALL_DIR}"
fi

"${VENV2_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

sed -i "1s|^#!.*|#!${VENV2_DIR}/bin/python|" "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp.py"

# Deploy systemd unit files with installer substitutions
SERVICE_DST="/etc/systemd/system/recieverServer.service"
SERVICE_PAGE_DST="/etc/systemd/system/serveCommand.service"

log "Installing/updating systemd unit files"
# Replace placeholders and write unit files as root
sed -e "s|__USER__|${USER_NAME}|g" -e "s|__HOME__|${HOME_DIR}|g" systemd/recieverServer.service | sudo tee "${SERVICE_DST}" > /dev/null
sed -e "s|__USER__|${USER_NAME}|g" -e "s|__HOME__|${HOME_DIR}|g" systemd/serveCommand.service | sudo tee "${SERVICE_PAGE_DST}" > /dev/null

sudo systemctl daemon-reload

# Try to enable and restart services, but continue even if restart fails so update completes
sudo systemctl enable recieverServer.service || true
sudo systemctl restart recieverServer.service || true
sudo systemctl enable serveCommand.service || true
sudo systemctl restart serveCommand.service || true

log "Update complete"
