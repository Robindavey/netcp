#!/usr/bin/env bash
set -e
source scripts/common.sh

log "Installing for user: ${USER_NAME}"

mkdir -p "${INSTALL_DIR}"
cp netcp.py recieverServer.py requirements.txt "${INSTALL_DIR}"

# Venvs
[ -d "${VENV_DIR}" ] || "${PYTHON_BIN}" -m venv "${VENV_DIR}"
[ -d "${VENV2_DIR}" ] || "${PYTHON_BIN}" -m venv "${VENV2_DIR}"

"${VENV2_DIR}/bin/pip" install --upgrade pip
"${VENV2_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

# Fix shebang
sed -i "1s|^#!.*|#!${VENV2_DIR}/bin/python|" "${INSTALL_DIR}/netcp.py"
chmod +x "${INSTALL_DIR}/netcp.py"

# Symlink
mkdir -p "${LOCAL_BIN}"
ln -sf "${INSTALL_DIR}/netcp.py" "${LOCAL_BIN}/netcp"

# systemd
require_root
sed \
  -e "s|__USER__|${USER_NAME}|g" \
  -e "s|__HOME__|${HOME_DIR}|g" \
  systemd/recieverServer.service \
  > "${SERVICE_DST}"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

log "Install complete"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

source ~/.bashrc
