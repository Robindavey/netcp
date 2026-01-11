#!/usr/bin/env bash
set -e
source scripts/common.sh
require_root

log "Stopping and removing systemd services"
# Services to remove
SERVICES=(recieverServer.service serveCommand.service)
for svc in "${SERVICES[@]}"; do
	systemctl stop "$svc" >/dev/null 2>&1 || true
	systemctl disable "$svc" >/dev/null 2>&1 || true
	rm -f "/etc/systemd/system/$svc" || true
done

log "Removing installed files and symlinks"
# Remove install directory
rm -rf "${INSTALL_DIR}"

# Remove symlinks (user local and /usr/local/bin)
rm -f "/usr/local/bin/netcp-add-sender"
rm -f "${LOCAL_BIN}/netcp"
rm -f "${LOCAL_BIN}/serve_command"

# Remove virtualenvs if present
rm -rf "${VENV_DIR}" || true
rm -rf "${VENV2_DIR}" || true

# Remove PATH export added by installer from user .bashrc if present
if [ -n "${HOME_DIR}" ] && [ -f "${HOME_DIR}/.bashrc" ]; then
	sed -i '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "${HOME_DIR}/.bashrc" || true
fi
sed -i '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' ~/.bashrc || true

systemctl daemon-reload || true
log "Uninstall complete"
