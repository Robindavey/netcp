#!/usr/bin/env bash
set -e

# ============================
# Load common functions / vars
# ============================
source scripts/common.sh

log "Installing for user: ${USER_NAME}"

# ============================
# Create install directory
# ============================
mkdir -p "${INSTALL_DIR}"
cp netcp.py recieverServer.py requirements.txt "${INSTALL_DIR}"

# ============================
# Create virtual environments
# ============================
[ -d "${VENV_DIR}" ] || "${PYTHON_BIN}" -m venv "${VENV_DIR}"
[ -d "${VENV2_DIR}" ] || "${PYTHON_BIN}" -m venv "${VENV2_DIR}"

# Upgrade pip and install requirements
"${VENV2_DIR}/bin/pip" install --upgrade pip
"${VENV2_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

# ============================
# Fix shebangs & permissions
# ============================
sed -i "1s|^#!.*|#!${VENV2_DIR}/bin/python|" "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp-add-sender.py"

# ============================
# Symlink scripts to PATH
# ============================
ln -sf "${INSTALL_DIR}/netcp-add-sender.py" "/usr/local/bin/netcp-add-sender"

mkdir -p "${LOCAL_BIN}"
ln -sf "${INSTALL_DIR}/netcp.py" "${LOCAL_BIN}/netcp"

# ============================
# Setup systemd service
# ============================
require_root  # Make sure script is run as root

sed \
  -e "s|__USER__|${USER_NAME}|g" \
  -e "s|__HOME__|${HOME_DIR}|g" \
  systemd/recieverServer.service \
  > "${SERVICE_DST}"

systemctl daemon-reexec
systemctl daemon-reload

systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"


sed \
  -e "s|__USER__|${USER_NAME}|g" \
  -e "s|__HOME__|${HOME_DIR}|g" \
  systemd/serveCommand.service \
  > "${SERVICE_DST_PAGE}"

# Reload and enable the service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "$(basename ${SERVICE_DST_PAGE})"
systemctl restart "$(basename ${SERVICE_DST_PAGE})"

log "Serve command page service installed and running"
# ============================
# Update PATH in bashrc
# ============================
log "Install complete"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

log "All done!"
