#!/bin/bash
# build.sh — builds ChromePicker.app without needing to open Xcode
set -e

echo "🔨 Building ChromePicker..."

SRCDIR="$(cd "$(dirname "$0")/ChromePicker" && pwd)"
OUTDIR="$HOME/Applications"
APPDIR="$OUTDIR/ChromePicker.app"

pkill -x ChromePicker || true
rm -rf "$APPDIR"
mkdir -p "$APPDIR/Contents/MacOS"
mkdir -p "$APPDIR/Contents/Resources"

swiftc \
  "$SRCDIR"/*.swift \
  -O \
  -o "$APPDIR/Contents/MacOS/ChromePicker" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -target arm64-apple-macos13.0 \
  -framework AppKit \
  -framework SwiftUI \
  -framework ServiceManagement

cp "$SRCDIR/Info.plist" "$APPDIR/Contents/Info.plist"
codesign --force --sign - "$APPDIR"

open "$APPDIR"

echo ""
echo "✅ Built and launched: $APPDIR"
echo ""
echo "Look for the ChromePicker icon in the menu bar. From its menu you can:"
echo "  • Set it as the default browser"
echo "  • Enable Launch at Login"
echo "  • Pause the picker or quit"
