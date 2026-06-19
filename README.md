# Today — floating todo app

A tiny native macOS todo app that **always floats on top** of every window
(including other apps' full-screen), **auto-opens on a schedule**, **speaks**
how many tasks you have pending, and supports **must-do daily tasks**.

- **App:** `~/Applications/FloatingTodo.app` (shows as **“Today”**)
- **Source:** `Sources/main.swift` (SwiftUI + AppKit)
- **Data:** `~/Library/Application Support/FloatingTodo/`
  - `todos.json` — regular tasks
  - `mustdo.json` — daily must-do tasks
  - `settings.json` — schedule + voice settings
- **Schedule:** `~/Library/LaunchAgents/com.rakib.floatingtodo.plist`
  (the app rewrites & reloads this itself whenever you change settings)

## Behavior
- **Always on top** — overlays all windows and full-screen apps; follows you across Spaces.
- **Auto-opens every hour** by default. Add your own **custom times**, toggle any
  on/off, and turn hourly off — all from the in-app **Settings** (gear, top-right).
- **Voice announcement** — when it opens on schedule, a male voice says how many
  tasks are pending (and how many are must-do). Toggle in Settings.
- **Must-do every day** — tasks in the locked red section reset each morning and
  are meant to be finished daily. While any remain, the red close button only
  **snoozes the app** (default 30 min, adjustable in Settings) and it reappears;
  **⌘M minimize** stays allowed. Once all must-do's are done, closing is normal.
- Manual opens don't speak; only scheduled (and snooze) opens do.

## Keyboard shortcuts
- **⌘W** — close (snoozes if must-do tasks remain, see above)
- **⌘M** — minimize · **⌘Q** — quit
- **⌘C / ⌘V / ⌘X / ⌘A** — standard editing in the text fields
- If the Mac is asleep at a scheduled time, it opens on the next wake.

## Rebuild after editing the source
```bash
cd "~/Downloads/todo mac app" && ./build.sh
```

## Turn auto-open off entirely (keep the app)
In Settings, turn off "Every hour" and disable all custom times — or:
```bash
launchctl unload ~/Library/LaunchAgents/com.rakib.floatingtodo.plist
```

## Uninstall completely
```bash
launchctl unload ~/Library/LaunchAgents/com.rakib.floatingtodo.plist
rm ~/Library/LaunchAgents/com.rakib.floatingtodo.plist
rm -rf ~/Applications/FloatingTodo.app
rm -rf ~/Library/Application\ Support/FloatingTodo
```
