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
