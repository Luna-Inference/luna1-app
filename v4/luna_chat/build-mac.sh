#!/bin/bash

# Build script for luna_chat macOS app
set -e  # Exit on error

# Navigate to project root
# cd "$(dirname "$0")/.."

# Define build directory
BUILD_DIR="build/macos"
DMG_PATH="build/luna_chat.dmg"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DMG_PATH" 2>/dev/null || true

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build macOS app
echo "🔨 Building macOS app (Debug mode)..."
flutter build macos --debug

# Create DMG
echo "📦 Creating DMG..."
APP_PATH="build/macos/Build/Products/Debug/luna_chat.app"
DMG_TEMP="build/dmg_temp"

# Create a temporary directory for the DMG contents
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy the app to the temp directory
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create a symlink to the Applications folder
ln -s "/Applications" "$DMG_TEMP/Applications"

# Create the DMG
hdiutil create -volname "Luna Chat" \
               -srcfolder "$DMG_TEMP" \
               -ov -format UDZO \
               -fs HFS+ \
               -imagekey zlib-level=9 \
               "$DMG_PATH"

# Clean up
rm -rf "$DMG_TEMP"

echo -e "\n✅ Build complete! DMG created at: $DMG_PATH"
echo "   You can install the app by double-clicking the DMG and dragging the app to your Applications folder."
echo "   Note: You might need to right-click and select 'Open' the first time due to macOS security settings."