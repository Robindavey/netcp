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

sudo systemctl restart "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_DST}"
log "Update complete"
