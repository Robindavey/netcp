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

# Replace placeholders into temp files and validate with systemd-analyze
TMP_RECIP=$(mktemp /tmp/recieverServer.service.XXXX)
TMP_SERVE=$(mktemp /tmp/serveCommand.service.XXXX)
sed -e "s|__USER__|${USER_NAME}|g" -e "s|__HOME__|${HOME_DIR}|g" systemd/recieverServer.service > "${TMP_RECIP}"
sed -e "s|__USER__|${USER_NAME}|g" -e "s|__HOME__|${HOME_DIR}|g" systemd/serveCommand.service > "${TMP_SERVE}"

# Validate unit files before installing
if command -v systemd-analyze >/dev/null 2>&1; then
	if ! systemd-analyze verify "${TMP_RECIP}" 2>/tmp/_srv_err || ! systemd-analyze verify "${TMP_SERVE}" 2>/tmp/_srv_err; then
		echo "Error: systemd unit validation failed:" >&2
		sed -n '1,200p' /tmp/_srv_err >&2 || true
		rm -f "${TMP_RECIP}" "${TMP_SERVE}" /tmp/_srv_err
		exit 1
	fi
fi

# Install validated unit files
sudo install -m 644 "${TMP_RECIP}" "${SERVICE_DST}"
sudo install -m 644 "${TMP_SERVE}" "${SERVICE_PAGE_DST}"

sudo systemctl daemon-reload

# Try to enable and restart services, but continue even if restart fails so update completes
sudo systemctl enable recieverServer.service || true
sudo systemctl restart recieverServer.service || true
sudo systemctl enable serveCommand.service || true
sudo systemctl restart serveCommand.service || true

log "Update complete"
