#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PDF Unlocker"
EXECUTABLE_NAME="PDFUnlocker"
BUNDLE_ID="com.needly.pdf-unlocker"
VERSION="0.1.2"
BUILD="3"
CONFIGURATION="debug"
VERIFY=false
LAUNCH=true

for arg in "$@"; do
  case "$arg" in
    --release)
      CONFIGURATION="release"
      ;;
    --no-launch)
      LAUNCH=false
      ;;
    --verify)
      VERIFY=true
      LAUNCH=true
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"

pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true
swift build -c "$CONFIGURATION"

BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_DIR/$EXECUTABLE_NAME" "$MACOS_DIR/$EXECUTABLE_NAME"

"$ROOT_DIR/script/generate_app_icon.sh"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

if [[ "$LAUNCH" == false ]]; then
  echo "Built $APP_BUNDLE"
  exit 0
fi

/usr/bin/open -n "$APP_BUNDLE"

if [[ "$VERIFY" == true ]]; then
  for _ in {1..20}; do
    if pgrep -x "$EXECUTABLE_NAME" >/dev/null; then
      echo "Verified: $APP_NAME is running."
      exit 0
    fi
    sleep 0.25
  done
  echo "Verification failed: $APP_NAME did not appear in the process list." >&2
  exit 1
fi
