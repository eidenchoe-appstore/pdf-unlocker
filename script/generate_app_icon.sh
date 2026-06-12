#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_JSON="$ROOT_DIR/icon.icon/icon.json"
ASSETS_DIR="$ROOT_DIR/icon.icon/Assets"
ICONSET_DIR="$ROOT_DIR/dist/AppIcon.iconset"
OUTPUT_DIR="$ROOT_DIR/Resources"
OUTPUT_ICON="$OUTPUT_DIR/AppIcon.icns"

IMAGE_NAME=""
if [[ -f "$ICON_JSON" ]]; then
  IMAGE_NAME="$(plutil -extract groups.0.layers.0.image-name raw -o - "$ICON_JSON" 2>/dev/null || true)"
fi

if [[ -n "$IMAGE_NAME" ]]; then
  SOURCE_ICON="$ASSETS_DIR/$IMAGE_NAME"
else
  SOURCE_ICON="$(find "$ASSETS_DIR" -maxdepth 1 -type f -iname '*.png' -print -quit)"
fi

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Missing source icon: $SOURCE_ICON" >&2
  exit 1
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR" "$OUTPUT_DIR"

sips -z 16 16 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICON"
echo "Generated $OUTPUT_ICON"
