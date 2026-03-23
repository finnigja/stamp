#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP="Stamp.app"
BINARY=".build/release/Stamp"

VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")

swift Scripts/generate-icon.swift
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/Stamp"
mv "Stamp.icns" "$APP/Contents/Resources/Stamp.icns"

cat > "$APP/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Stamp</string>
    <key>CFBundleIdentifier</key>
    <string>com.stamp.app</string>
    <key>CFBundleName</key>
    <string>Stamp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleIconFile</key>
    <string>Stamp</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Built $APP"
