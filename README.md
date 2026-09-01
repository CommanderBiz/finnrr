# 🦁 Finnrr

**Finnrr** (Finamp → Finnrr) is a modern, open-source music player for [Jellyfin](https://jellyfin.org/), forked from [Finamp](https://github.com/jmshrv/finamp). It gives you a streaming-app experience (Spotify/Apple-Music-style) for the music you already own — with a focus on **Linux desktop** and tight integration with the **Finnrr Lyrics** Jellyfin plugin.

Finnrr = *Chaldean 23*, the Royal Star of the Lion.

> [!IMPORTANT]
> Linux desktop development happens on the **`redesign`** branch. The `main` branch has no Linux desktop support (upstream Finamp removed it) — for anything desktop-related, `git checkout redesign`.

---

## What's different from upstream Finamp

This fork is built for **self-hosted desktop listening**:

- 🖥️ **First-class Linux desktop** — native build via the `redesign` branch, with `media_kit`/libmpv audio (direct-play — FLAC stays FLAC), Impeller rendering, and a proper desktop window.
- 🦁 **Finnrr Lyrics plugin** — the companion [Jellyfin lyrics plugin](https://github.com/CommanderBiz/finnrr-plugin-lyrics) that auto-syncs lyrics for newly added music after every library scan.
- 📦 **One-command reproducible builds + portable AppImage** — see [LINUX_BUILD.md](LINUX_BUILD.md).
- 🏠 **Modern Home screen** — quick actions, new arrivals, favorites (carried from the redesign branch).

---

## The Finnrr stack

| Component | Repo | What it does |
|---|---|---|
| **Finnrr app** | `CommanderBiz/finnrr` (this repo) | Jellyfin music player client (desktop, Android, iOS) |
| **Finnrr Lyrics plugin** | `CommanderBiz/finnrr-plugin-lyrics` | Jellyfin server plugin: downloads synced lyrics from [lrclib.net](https://lrclib.net) + auto-syncs new music |

---

## Features

- A welcoming UI that looks modern & unique, but still familiar
- **Linux desktop** support (the focus of this fork) — native audio, no transcoding for common formats
- Beautiful dynamic colors that adapt to your media
- Audio volume normalization (ReplayGain)
- **Synced lyrics** (via the Finnrr Lyrics plugin) in the Now Playing screen
- Downloading files for offline listening (mobile)
- Full support for Jellyfin's Playback Reporting
- AudioMuse integration for sonic analysis and improved mixes

***You need your own Jellyfin server.** If you don't have one, see [jellyfin.org](https://jellyfin.org/).*

---

## Installing / building

### Linux desktop (AppImage or build)

Prebuilt builds and AppImages are published from the `redesign` branch. To build from source:

```bash
git clone git@github.com:CommanderBiz/finnrr.git
cd finnrr
git checkout redesign
./build/build_linux.sh              # debug build
BUILD=release ./build/build_linux.sh   # release build
./build/build_appimage.sh           # package a portable AppImage (after release)
```

Full prerequisites, gotchas, and docs are in **[LINUX_BUILD.md](LINUX_BUILD.md)** (Flutter ≥ 3.9, Rust, libmpv, etc.).

### Android / iOS

The app is a Flutter project — `flutter run` on your device/emulator, or build an APK with `flutter build apk`. (Official store listings are planned once branding is finalized.)

---

## Setting up the Jellyfin Lyrics plugin

Finnrr's synced lyrics come from the **Finnrr Lyrics** server plugin. This works in *any* Jellyfin client (desktop Finnrr, web, mobile) — the plugin fills the server, clients display it.

> [!NOTE]
> The plugin repo (`CommanderBiz/finnrr-plugin-lyrics`) is **public** and ships an installable release (`v1.0.0.0`). Just add the repo and install — no extra steps needed:

1. **Jellyfin 10.11.6 or newer.**
2. If the old **LrcLib** plugin (`jellyfin-plugin-lrclib`) is installed, uninstall it and restart Jellyfin (this plugin also auto-marks it for removal on startup).
3. **Add the plugin repository** to Jellyfin:
   ```
   https://raw.githubusercontent.com/CommanderBiz/finnrr-plugin-lyrics/master/manifest.json
   ```
4. **Plugin Catalog → Finnrr Lyrics** (Metadata category) → **Install** → restart Jellyfin.
5. Run **Download and upgrade lyrics** once under Scheduled Tasks to backfill the library.
6. **Scan all libraries.** Everything added afterwards gets lyrics **automatically** (auto-sync on scan).

### Plugin settings (defaults shown)

| Setting | Default | What it does |
|---|---|---|
| Use strict search | off | Exact match only (artist + title) instead of fuzzy |
| Exclude artist / album name | album off | Removes those from search parameters |
| Filter matches by song length | on (15s tolerance) | Rejects lyrics whose duration differs too much |
| Skip repeated misses | on | Backs off 1, 3, 7, 30 days for tracks with no lyrics online |
| Limit work per run | on (2000) | Caps tracks checked per scheduled run |
| **Auto-sync new music (Finnrr)** | **on (100)** | After each library scan, fetches lyrics for newest tracks missing them |
| LRCLIB server URL | lrclib.net | Point at a self-hosted LRCLIB instance if you run one |

---

## FAQ

##### Is Finnrr free?

Yes. It's open-source software, like Jellyfin itself. It does not bundle any music — you bring your own library to your own Jellyfin server.

##### Which formats are supported?

Everything your Jellyfin server supports. On desktop, common formats (FLAC, MP3, AAC, OGG, etc.) play in **direct-play** — no transcoding.

##### How do I get help?

Open an issue on this repository. For plugin issues, open one on `CommanderBiz/finnrr-plugin-lyrics`.

---

## Contributing

Finnrr is a personal fork of Finamp (GPL-3.0). The bulk of the app code is upstream [Finamp](https://github.com/jmshrv/finamp) — huge thanks to its community. This fork adds the desktop focus, branding, and the lyrics plugin integration.

- Code: fork, branch off `redesign`, open a PR.
- The `main` branch is kept for upstream sync.

---

## Known Issues / Notes

- The `redesign` branch is the actively-developed one; `main` is desktop-obsolete.
- The plugin repo is public with an installable v1.0.0.0 release.
- Branding (logo, store listings) is in progress — the app is currently named **Finnrr** in the UI but still ships with the upstream package identifiers (`com.unicornsonlsd.finamp`).

---

*Name origin: Finamp → Finnrr (Chaldean 23, the Royal Star of the Lion). Original name source: [r/jellyfin](https://www.reddit.com/r/jellyfin/comments/hjxshn/jellyamp_crossplatform_desktop_music_player/fwqs5i0/).*
