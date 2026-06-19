#!/bin/bash
set -euo pipefail

# Build FloatingTodo.app from Sources/main.swift and install it to ~/Applications.
# Re-run this any time you change the source.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="FloatingTodo"
APP_DISPLAY="Today"
BUNDLE_ID="com.rakib.floatingtodo"
INSTALL_DIR="$HOME/Applications"
APP_BUNDLE="$INSTALL_DIR/$APP_NAME.app"

echo "→ Compiling $APP_NAME…"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc -O \
  -framework SwiftUI -framework AppKit \
  "$PROJECT_DIR/Sources/main.swift" \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "→ Installing icon…"
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
  cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "→ Writing Info.plist…"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_DISPLAY</string>
    <key>CFBundleDisplayName</key><string>$APP_DISPLAY</string>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIconName</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so macOS launches it without quarantine friction.
codesign --force --deep -s - "$APP_BUNDLE" >/dev/null 2>&1 || true

echo "✓ Installed: $APP_BUNDLE"
