#!/usr/bin/env bash
set -e
source scripts/common.sh
require_root

log "Stopping service"
systemctl stop "${SERVICE_NAME}"
systemctl disable "${SERVICE_NAME}"
rm -f "${SERVICE_DST}"

log "Removing files"
rm -rf "${INSTALL_DIR}"
rm -f "${LOCAL_BIN}/netcp"

systemctl daemon-reload
log "Uninstall complete"
