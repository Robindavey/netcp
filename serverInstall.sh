#!/usr/bin/env bash
set -e

command -v git >/dev/null || sudo apt install -y git
command -v python3 >/dev/null || sudo apt install -y python3 python3-venv

REPO="https://github.com/YOURORG/netcp.git"
DIR="/tmp/netcp-install"

rm -rf "$DIR"
git clone "$REPO" "$DIR"
cd "$DIR"
make install
