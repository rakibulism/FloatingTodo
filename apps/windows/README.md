# Today — Windows (Tauri)

A thin **Tauri v2** desktop shell that wraps the shared web UI
([`../web/app`](../web/app)) and adds the platform pieces that make it behave
like the macOS app:

- **Always on top** — `alwaysOnTop: true` in `src-tauri/tauri.conf.json`.
- **Auto-launch at login** — `tauri-plugin-autostart` (passes `--auto`).
- **Hourly re-open** — registers a Windows Scheduled Task (`TodayHourly`) on first run (see `src-tauri/src/main.rs`).
- **Voice** — handled by the shared web UI (Web Speech API) on launch.

> ⚠️ Built and tested on **macOS only** so far. The source is standard Tauri v2;
> compile it **on Windows** (or cross-compile) to produce installers. The steps
> below are the standard Tauri flow — not yet run in CI.

## Prerequisites (on Windows)
- [Rust](https://rustup.rs) and the MSVC build tools
- Tauri CLI: `cargo install tauri-cli --version "^2"`
- WebView2 runtime (preinstalled on Windows 10/11)

## Build
```bash
cd apps/windows/src-tauri
# one-time: generate the icon set from the shared icon
cargo tauri icon ../../web/assets/icon.png
# dev
cargo tauri dev
# release installers (.msi / .nsis)
cargo tauri build
```
The frontend is pulled from `../../web/app` (set as `build.frontendDist`).

## Notes
- The Scheduled Task mirrors the macOS `launchd` hourly schedule. Remove it with `schtasks /Delete /TN TodayHourly /F`.
- `target/` and generated `gen/` are gitignored.
