#!/bin/bash
set -euo pipefail

# Assembles a loadable Chrome (MV3) extension into dist/ by bundling the shared
# web app (../web/app) as the toolbar popup, plus the manifest and icons.

DIR="$(cd "$(dirname "$0")" && pwd)"
DIST="$DIR/dist"
APP="$DIR/../web/app"
SRC_ICON="$DIR/../web/assets/icon-1024.png"

echo "→ Building extension…"
rm -rf "$DIST"
mkdir -p "$DIST/app" "$DIST/icons"

cp -R "$APP/." "$DIST/app/"
cp "$DIR/popup.html" "$DIST/popup.html"
cp "$DIR/manifest.json" "$DIST/manifest.json"

for s in 16 48 128; do
  sips -z $s $s "$SRC_ICON" --out "$DIST/icons/icon-$s.png" >/dev/null
done

echo "✓ Built: $DIST"
echo "  Load it → chrome://extensions → enable Developer mode → Load unpacked → select the dist/ folder"
