#!/usr/bin/env bash
set -e
source scripts/common.sh

log "Updating netcp"

cp netcp.py recieverServer.py requirements.txt "${INSTALL_DIR}"

"${VENV2_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

sed -i "1s|^#!.*|#!${VENV2_DIR}/bin/python|" "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp.py"

sudo systemctl restart "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_DST}"
log "Update complete"
