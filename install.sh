#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="TimerPro"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
INSTALL_DIR="/Applications"

echo "==> Building ${APP_NAME}..."
bash "${SCRIPT_DIR}/build.sh"

echo "==> Installing to ${INSTALL_DIR}..."
if [ -d "${INSTALL_DIR}/${APP_NAME}.app" ]; then
    echo "  Removing existing installation..."
    rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
fi

cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/"
xattr -cr "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

echo ""
echo "✓ Installed to ${INSTALL_DIR}/${APP_NAME}.app"
echo ""
echo "Launching ${APP_NAME}..."
open "${INSTALL_DIR}/${APP_NAME}.app"
