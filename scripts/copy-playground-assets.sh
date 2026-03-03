#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WEB_DIST="$ROOT_DIR/playground/web/dist"

if [ ! -d "$WEB_DIST" ]; then
  echo "Error: $WEB_DIST not found. Run 'pnpm build' first."
  exit 1
fi

# iOS — copy to Resources/
IOS_RESOURCES="$ROOT_DIR/playground/ios/RynBridgePlayground/Resources"
mkdir -p "$IOS_RESOURCES"
cp "$WEB_DIST/index.html" "$IOS_RESOURCES/"
cp "$WEB_DIST/playground.js" "$IOS_RESOURCES/"
echo "Copied web dist → $IOS_RESOURCES"

# Android — copy to assets/
ANDROID_ASSETS="$ROOT_DIR/android/playground/src/main/assets"
mkdir -p "$ANDROID_ASSETS"
cp "$WEB_DIST/index.html" "$ANDROID_ASSETS/"
cp "$WEB_DIST/playground.js" "$ANDROID_ASSETS/"
echo "Copied web dist → $ANDROID_ASSETS"

echo "Done."
