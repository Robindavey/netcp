#!/usr/bin/env bash
set -e

source scripts/common.sh

log "Installing for user: ${USER_NAME}"

# ----------------------------
# Create install directory
# ----------------------------
mkdir -p "${INSTALL_DIR}"
cp netcp.py recieverServer.py requirements.txt serve_command.py "${INSTALL_DIR}"

# ----------------------------
# Create virtual environments
# ----------------------------
[ -d "${VENV_DIR}" ] || "${PYTHON_BIN}" -m venv "${VENV_DIR}"
[ -d "${VENV2_DIR}" ] || "${PYTHON_BIN}" -m venv "${VENV2_DIR}"

"${VENV2_DIR}/bin/pip" install --upgrade pip
"${VENV2_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

# ----------------------------
# Fix shebangs & permissions
# ----------------------------
sed -i "1s|^#!.*|#!${VENV2_DIR}/bin/python|" "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp-add-sender.py"
chmod +x "${INSTALL_DIR}/serve_command.py"

# ----------------------------
# Symlink scripts to PATH
# ----------------------------
ln -sf "${INSTALL_DIR}/netcp-add-sender.py" "/usr/local/bin/netcp-add-sender"

mkdir -p "${LOCAL_BIN}"
ln -sf "${INSTALL_DIR}/netcp.py" "${LOCAL_BIN}/netcp"
ln -sf "${INSTALL_DIR}/serve_command.py" "${LOCAL_BIN}/serve_command"

# ----------------------------
# Setup systemd services
# ----------------------------
require_root

# recieverServer
SERVICE_DST="/etc/systemd/system/recieverServer.service"
SERVICE_NAME="recieverServer.service"

sed \
  -e "s|__USER__|${USER_NAME}|g" \
  -e "s|__HOME__|${HOME_DIR}|g" \
  systemd/recieverServer.service \
  > "${SERVICE_DST}"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

# serveCommand
SERVICE_DST_PAGE="/etc/systemd/system/serveCommand.service"
SERVICE_NAME_PAGE="serveCommand.service"

sed \
  -e "s|__USER__|${USER_NAME}|g" \
  -e "s|__HOME__|${HOME_DIR}|g" \
  systemd/serveCommand.service \
  > "${SERVICE_DST_PAGE}"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "${SERVICE_NAME_PAGE}"
systemctl restart "${SERVICE_NAME_PAGE}"

log "Both systemd services installed and running"

# ----------------------------
# Update PATH
# ----------------------------
log "Install complete"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
log "All done! Please restart your shell to update PATH."
