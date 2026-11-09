#!/usr/bin/env bash
# Build Ace Link.app (universal, ad-hoc signed) and package it into a versioned DMG.
#
# Usage: scripts/build-dmg.sh [version]
#   version defaults to the contents of the VERSION file.
# Output: builds/Ace.Link.<version>.dmg (+ .sha256)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-$(tr -d '[:space:]' < VERSION)}"
BUILD_DIR="$ROOT/builds"
DERIVED="$BUILD_DIR/DerivedData"
STAGE="$BUILD_DIR/Ace.Link.$VERSION"
DMG="$BUILD_DIR/Ace.Link.$VERSION.dmg"

echo "==> Building Ace Link $VERSION"
rm -rf "$DERIVED" "$STAGE" "$DMG" "$DMG.sha256"
mkdir -p "$BUILD_DIR"

xcodebuild \
  -project "Ace Link.xcodeproj" \
  -target "Ace Link" \
  -configuration Release \
  SYMROOT="$DERIVED" \
  OBJROOT="$DERIVED/obj" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  INFOPLIST_PREPROCESS=NO \
  build | tee "$BUILD_DIR/xcodebuild.log" | grep -E "error:|warning: .*deprecated|BUILD (SUCCEEDED|FAILED)" || true

APP="$DERIVED/Release/Ace Link.app"
if [[ ! -d "$APP" ]]; then
  echo "Build failed, see $BUILD_DIR/xcodebuild.log" >&2
  exit 1
fi

# Stamp the version into the bundle so the in-app update check and the
# Docker image tag (sixblack/acelink:<version>) always match the release.
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"

# Ad-hoc sign (required to launch on Apple silicon). The app is not notarized.
codesign --force --deep --sign - "$APP"
codesign --verify --verbose "$APP"

echo "==> Packaging $DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Ace Link $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

(cd "$BUILD_DIR" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "==> Done: $DMG"
cat "$DMG.sha256"
