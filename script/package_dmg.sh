#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PDF Unlocker"
EXECUTABLE_NAME="PDFUnlocker"
DMG_NAME="PDFUnlocker.dmg"
STAGING_DIR="$ROOT_DIR/dist/dmg-staging"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/dist/$DMG_NAME"

cd "$ROOT_DIR"

"$ROOT_DIR/script/build_and_run.sh" --release --no-launch
pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$ROOT_DIR/README.md" "$STAGING_DIR/README.md"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH"
echo "Created $DMG_PATH"
