#!/usr/bin/env bash
# build_appimage.sh — package the Finnrr release build as a portable AppImage.
# Depends on build_linux.sh having produced a release bundle first, and on
# linuxdeploy being available (see LINUX_BUILD.md).
#
# Usage:  BUILD=release ./build/build_linux.sh && ./build/build_appimage.sh
set -euo pipefail

APP_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_HOME"

BUNDLE=build/linux/x64/release/bundle
APPDIR=/tmp/finnrr-AppDir
OUT="Finnrr-x86_64.AppImage"

LINUXDEPLOY="${LINUXDEPLOY:-/tmp/linuxdeploy-x86_64.AppImage}"

echo "=== Finnrr AppImage builder ==="
[ -f "$BUNDLE/finamp" ] || { echo "Release bundle missing — run: BUILD=release ./build/build_linux.sh"; exit 1; }
[ -f "$LINUXDEPLOY" ] || { echo "linuxdeploy missing at $LINUXDEPLOY — download from github.com/linuxdeploy/linuxdeploy"; exit 1; }

echo "=== 1. build AppDir ==="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/512x512/apps"

echo "=== 2. stage Flutter bundle (binary + lib + data stay together) ==="
cp -r "$BUNDLE/finamp" "$APPDIR/usr/bin/"
cp -r "$BUNDLE/lib" "$APPDIR/usr/bin/"
cp -r "$BUNDLE/data" "$APPDIR/usr/bin/"

echo "=== 3. desktop file ==="
cat > "$APPDIR/usr/share/applications/finnrr.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Finnrr
GenericName=Music Player
Comment=An open source Jellyfin music player (Finamp fork)
Icon=finamp
Exec=finamp
Terminal=false
Categories=AudioVideo;Audio;Player;Music;
StartupWMClass=finamp
EOF

echo "=== 4. plugin .so files must ALSO be on the loader path ==="
# Several Dart FFI plugins (isar, flutter_discord_rpc via flutter_rust_bridge,
# media_kit) load their .so by bare name through LD_LIBRARY_PATH, which the
# AppImage runtime points at usr/lib. Flutter bundles them in usr/bin/lib (not
# on that path), so without this they fail to load at startup:
#   "Failed to load dynamic library 'libisar.so'"
#   "Failed to load dynamic library 'libflutter_discord_rpc.so'"
# Copy ALL of them into usr/lib (keep the usr/bin/lib copies for the Flutter
# plugin registrant, which loads by absolute path).
mkdir -p "$APPDIR/usr/lib"
cp "$APPDIR/usr/bin/lib/"*.so "$APPDIR/usr/lib/"
echo "  copied $(ls "$APPDIR/usr/bin/lib/"*.so | wc -l) plugin .so -> usr/lib"

echo "=== 5. icon ==="
cp assets/icon/linux/512x512/apps/finamp.png \
   "$APPDIR/usr/share/icons/hicolor/512x512/apps/finamp.png"

echo "=== 6. run linuxdeploy (bundle system deps + emit AppImage) ==="
"$LINUXDEPLOY" \
    --appdir "$APPDIR" \
    --executable "$APPDIR/usr/bin/finamp" \
    --desktop-file "$APPDIR/usr/share/applications/finnrr.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/512x512/apps/finamp.png" \
    --output appimage 2>&1 | tail -8

echo
echo "✅ AppImage: $APP_HOME/$OUT ($(du -h "$OUT" | cut -f1))"
echo "   sha256: $(sha256sum "$OUT" | cut -c1-32)"
echo "   Test:   ./$OUT"
