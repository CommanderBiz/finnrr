#!/usr/bin/env bash
# build_linux.sh — reproducible Finnrr (Finamp fork) Linux desktop build.
# Captures every fix needed to build the 'redesign' branch on a fresh Ubuntu/Debian box.
# Usage:  ./build_linux.sh            (debug build)
#         BUILD=release ./build_linux.sh
set -euo pipefail

APP_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_MODE="${BUILD:-debug}"
FLUTTER_BIN="$(command -v flutter || true)"

echo "=== Finnrr Linux build script ==="
echo "App dir:      $APP_HOME"
echo "Build mode:   $BUILD_MODE"

# ---------- 1. Prerequisite checks ----------
echo; echo "=== 1. Checking prerequisites ==="
missing=()
for tool in flutter cargo cmake ninja pkg-config clang; do
  if ! command -v "$tool" >/dev/null 2>&1; then missing+=("$tool"); fi
done
if ! ldconfig -p 2>/dev/null | grep -q 'libmpv\.so'; then missing+=("libmpv.so (install: sudo apt install libmpv2)"); fi

if [ "${#missing[@]}" -gt 0 ]; then
  echo "MISSING PREREQUISITES: ${missing[*]}"
  echo
  echo "On Ubuntu/Debian:"
  echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal   # Rust"
  echo "  sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libmpv2 liblzma-dev libstdc++-12-dev"
  echo "  # Flutter stable (Dart >=3.9 needed by redesign): https://docs.flutter.dev/get-started/install"
  echo "  #   then: flutter config --enable-linux-desktop"
  echo "ABORTING"
  exit 1
fi
echo "All prerequisites present."

# ---------- 2. flutter_discord_rpc cargo dependency fix ----------
# The 'redesign' branch uses flutter_discord_rpc (Rust Discord presence). Its
# Cargo.toml pins discord-rich-presence WITHOUT a rev; HEAD was force-pushed and
# the v1.x API no longer matches the plugin. Pin to tag 0.2.5 (compatible API).
# This is applied to the pub-cache copy (out-of-tree), idempotently.
echo; echo "=== 2. Patching flutter_discord_rpc discord-rich-presence pin (0.2.5) ==="
FDRP="$(find "$HOME/.pub-cache/hosted/pub.dev" -maxdepth 1 -type d -name 'flutter_discord_rpc-*' 2>/dev/null | sort -V | tail -1)"
if [ -z "$FDRP" ]; then
  echo "flutter_discord_rpc not in pub-cache yet — will need 'flutter pub get' first. Run pub get, then re-run this script."
  exit 1
fi
echo "Plugin dir: $FDRP"
for cargo in "$FDRP/Cargo.toml" "$FDRP/rust/Cargo.toml"; do
  if [ -f "$cargo" ] && ! grep -q 'tag = "0.2.5"' "$cargo"; then
    sed -i 's|discord-rich-presence = { git = "https://github.com/vionya/discord-rich-presence.git" }|discord-rich-presence = { git = "https://github.com/vionya/discord-rich-presence.git", tag = "0.2.5" }|' "$cargo"
    echo "  pinned $cargo -> 0.2.5"
  fi
done
# Fix stale Cargo.lock files (version 0.2.4 + stale rev) if present
for lock in "$FDRP/Cargo.lock" "$FDRP/rust/Cargo.lock"; do
  if [ -f "$lock" ]; then
    sed -i 's|#5620e8901566290a583f9354205686b18628ba1b|#18ecbe78c7030a31932efb550e738fef94aa7a6b|g; s|version = "0.2.4"|version = "0.2.5"|g' "$lock"
    echo "  fixed $lock rev/version"
  fi
done
# Clear broken cargo git db if the pinned rev is missing
DB="$HOME/.cargo/git/db/discord-rich-presence-d428e9cb94436f0d"
if [ -d "$DB" ] && ! git --git-dir="$DB" cat-file -e 18ecbe78c7030a31932efb550e738fef94aa7a6b^{commit} 2>/dev/null; then
  echo "  clearing stale cargo git db..."
  rm -rf "$DB" "$HOME/.cargo/git/checkouts/discord-rich-presence-"* 2>/dev/null || true
fi

# ---------- 3. Git rewrite guard ----------
# A global 'url.git@github.com:.insteadof=https://github.com/' breaks cargo's
# fetch (cargo can't use the SSH agent the same way). Warn + remove if present.
echo; echo "=== 3. Git insteadOf guard ==="
if git config --global --get-regexp '^url\..*\.insteadof' 2>/dev/null | grep -q 'https://github.com/'; then
  echo "WARNING: global git https->ssh rewrite detected; it breaks cargo fetch."
  echo "Removing it (keep direct git@ remotes for your own repos)."
  git config --global --unset-all "$(git config --global --get-regexp '^url\..*\.insteadof' | grep 'https://github.com/' | awk '{print $1}')" || true
else
  echo "No problematic rewrite."
fi

# ---------- 4. Generate l10n + build ----------
echo; echo "=== 4. Building (flutter pub get + build) ==="
cd "$APP_HOME"
flutter pub get 2>&1 | tail -3
if [ "$BUILD_MODE" = "release" ]; then
  flutter build linux --release
  echo; echo "✅ Release bundle: $APP_HOME/build/linux/x64/release/bundle/"
else
  flutter build linux --debug
  echo; echo "✅ Debug bundle: $APP_HOME/build/linux/x64/debug/bundle/"
fi
echo
echo "Run it: $APP_HOME/build/linux/x64/$([ "$BUILD_MODE" = release ] && echo release || echo debug)/bundle/finamp"
