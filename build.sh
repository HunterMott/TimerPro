#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="TimerPro"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"
BINARY_NAME="TimerPro"

echo "==> Building ${APP_NAME} with Swift Package Manager..."
cd "${SCRIPT_DIR}"
swift build -c release 2>&1

BINARY_PATH="${SCRIPT_DIR}/.build/release/${BINARY_NAME}"
if [ ! -f "${BINARY_PATH}" ]; then
    echo "ERROR: Build failed - binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "==> Creating .app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "==> Copying binary..."
cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/${BINARY_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${BINARY_NAME}"

echo "==> Copying Info.plist..."
cp "${SCRIPT_DIR}/Sources/TimerPro/Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "==> Removing quarantine attribute..."
xattr -cr "${APP_BUNDLE}" 2>/dev/null || true

echo ""
echo "✓ Build complete: ${APP_BUNDLE}"
echo ""
echo "To run directly:"
echo "  open \"${APP_BUNDLE}\""
