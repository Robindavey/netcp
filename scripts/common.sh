#!/usr/bin/env bash
set -e

USER_NAME="${SUDO_USER:-$(whoami)}"
HOME_DIR="$(getent passwd "${USER_NAME}" | cut -d: -f6)"
INSTALL_DIR="${HOME_DIR}/netcp"

VENV_DIR="${INSTALL_DIR}/venv"
VENV2_DIR="${INSTALL_DIR}/venv2"
PYTHON_BIN="/usr/bin/python3"

LOCAL_BIN="${HOME_DIR}/.local/bin"
SERVICE_NAME="recieverServer.service"
SERVICE_DST="/etc/systemd/system/${SERVICE_NAME}"
COMMAND_PAGE = "/etc/systemd/system/"
log() {
  echo "[netcp] $1"
}

require_root() {
  if [ "$EUID" -ne 0 ]; then
    log "Re-run with sudo"
    exit 1
  fi
}
