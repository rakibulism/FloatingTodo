# Today — macOS (native)

Native SwiftUI/AppKit app. Floats above every window (incl. other apps'
full-screen), auto-opens on a schedule via `launchd`, speaks your pending count
in a male voice, and enforces must-do daily tasks.

- **App:** `~/Applications/FloatingTodo.app` (shows as **“Today”**)
- **Source:** [`Sources/main.swift`](Sources/main.swift)
- **Data:** `~/Library/Application Support/FloatingTodo/` (`todos.json`, `mustdo.json`, `settings.json`)
- **Schedule:** `~/Library/LaunchAgents/com.rakib.floatingtodo.plist` (the app rewrites & reloads it from Settings)

## Build
Requires macOS 13+ and the Swift toolchain (`xcode-select --install`).
```bash
./build.sh
open -a ~/Applications/FloatingTodo.app
```
`build.sh` compiles to `~/Applications/FloatingTodo.app`, installs the icon, and
ad-hoc signs it. The app installs/refreshes its LaunchAgent on first launch.

## Behavior
- Always on top, across Spaces, over full-screen apps.
- Auto-opens hourly by default; add custom times and toggle them in Settings.
- Speaks pending count on scheduled open (toggle in Settings).
- Must-do tasks reset daily; closing while any remain **snoozes** (configurable, default 30 min) instead of dismissing. ⌘M minimize is always allowed.
- Shortcuts: ⌘W close · ⌘M minimize · ⌘Q quit · ⌘C/⌘V/⌘X/⌘A in fields.

## Uninstall
```bash
launchctl unload ~/Library/LaunchAgents/com.rakib.floatingtodo.plist
rm ~/Library/LaunchAgents/com.rakib.floatingtodo.plist
rm -rf ~/Applications/FloatingTodo.app ~/Library/Application\ Support/FloatingTodo
```
