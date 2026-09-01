# Building Finnrr (Finamp fork) for Linux desktop

Finnrr tracks the upstream **`redesign`** branch — the actively-maintained desktop build
with native audio, the Home screen, and `background_downloader`. The `main` branch has no
Linux desktop support (upstream removed it) and is not used for desktop builds.

> Repo: `github.com/CommanderBiz/finnrr` — Linux desktop work happens on `redesign`.

## One-command build

```bash
cd finnrr
./build/build_linux.sh            # debug
BUILD=release ./build/build_linux.sh   # release
```

The script checks prerequisites, applies the one out-of-tree fix needed
(`flutter_discord_rpc`'s Rust dependency), and runs the build. Output lands in
`build/linux/x64/{debug,release}/bundle/`.

## Prerequisites (Ubuntu/Debian)

```bash
# Flutter — redesign needs Dart >= 3.9 (current stable works)
#   https://docs.flutter.dev/get-started/install
flutter config --enable-linux-desktop

# Rust — needed to compile flutter_discord_rpc (Discord presence, Rust plugin)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal

# System libs — clang/cmake/ninja for Flutter Linux, libmpv for media_kit audio
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libmpv2
```

## Known gotchas (encoded into build_linux.sh)

1. **`discord-rich-presence` crate pin.** `flutter_discord_rpc` 1.1.0's `Cargo.toml`
   references the crate without a revision; upstream force-pushed HEAD, and the v1.x API
   no longer compiles against the plugin. The build script pins it to tag **`0.2.5`**
   (API-compatible) inside the pub-cache copy and fixes the stale `Cargo.lock`.

2. **Git `https→ssh` rewrite breaks cargo.** A global
   `url.git@github.com:.insteadof=https://github.com/` makes cargo try SSH for crate
   fetches, which fails (cargo can't use the SSH agent). The script detects and removes it.
   Your own repos should use explicit `git@` remotes instead of the global rewrite.

3. **Stale cargo git db.** If cargo errors with `revision ... not found` for the crate,
   the script clears `~/.cargo/git/db/discord-rich-presence-*` so cargo re-fetches.

## Running

```bash
build/linux/x64/debug/bundle/finamp
```

Finnrr connects to your Jellyfin (e.g. Laptop0 at `192.168.86.70:8096`). Audio plays
through libmpv (media_kit) in direct-play — FLAC stays FLAC, no transcoding.

## Useful dev commands

```bash
flutter gen-l10n          # regenerate localizations after editing lib/l10n/*.arb
flutter run -d linux      # hot-reload dev loop
```


## AppImage packaging

The release build can be packaged as a portable, self-contained AppImage
(no Flutter/Rust/libmpv needed on the target machine):

=== Finnrr Linux build script ===
App dir:      /home/kernel/projects/finnrr
Build mode:   release

=== 1. Checking prerequisites ===
MISSING PREREQUISITES: flutter cargo libmpv.so (install: sudo apt install libmpv2)

On Ubuntu/Debian:
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal   # Rust
  sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev libmpv2 liblzma-dev libstdc++-12-dev
  # Flutter stable (Dart >=3.9 needed by redesign): https://docs.flutter.dev/get-started/install
  #   then: flutter config --enable-linux-desktop
ABORTING
=== Finnrr AppImage builder ===
=== 1. build AppDir ===
=== 2. stage Flutter bundle (binary + lib + data stay together) ===
=== 3. desktop file ===
=== 4. plugin .so files must ALSO be on the loader path ===
  copied 11 plugin .so -> usr/lib
=== 5. icon ===
=== 6. run linuxdeploy (bundle system deps + emit AppImage) ===
[appimage/stderr]          https://docs.appimage.org/packaging-guide/optional/appstream.html#using-the-appstream-generator
[appimage/stderr] Generating squashfs...
[appimage/stderr] Downloading runtime file from https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64
[appimage/stderr] Downloaded runtime binary of size 944632
[appimage/stderr] Could not open regular file for writing as destination: Text file busy
[appimage/stderr] mksquashfs (pid 134869) exited with code 1
[appimage/stderr] sfs_mksquashfs error
ERROR: Failed to run plugin: appimage (exit code: 1) 

Gotcha encoded in the script: Flutter FFI plugins (isar, flutter_discord_rpc,
media_kit) load their .so by bare name through LD_LIBRARY_PATH, which the AppImage
runtime points at usr/lib -- but Flutter bundles them in usr/bin/lib (not on that
path), causing "Failed to load dynamic library" at startup. The script copies
all plugin .so files into usr/lib so the loader finds them.
