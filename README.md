# Today — a floating to-do, everywhere

A to-do app whose whole point is that **it shows up so you can't ignore it** —
floating on top, opening itself on a schedule, reading out what's still pending,
and enforcing must-do daily tasks.

This is a **monorepo**: one shared web UI powers the web, Windows, and Android
targets, while macOS is its own polished native app.

```
.
├── apps/
│   ├── macos/             Native SwiftUI/AppKit app (always-on-top + launchd + voice)
│   ├── web/               Marketing site + the installable PWA  (deployed on Vercel)
│   │   ├── index.html     landing page
│   │   └── app/           the installable PWA (shared web UI)
│   ├── windows/           Tauri shell — wraps apps/web/app + always-on-top + autostart
│   ├── android/           Capacitor shell — wraps apps/web/app + scheduled notifications
│   ├── chrome-extension/  MV3 toolbar popup — bundles apps/web/app
│   ├── figma-plugin/      Figma + FigJam plugin (UI panel + canvas insert)
│   └── figma-widget/      Figma + FigJam on-canvas widget (synced state)
└── README.md
```

The **shared web UI** lives in [`apps/web/app`](apps/web/app); the Windows and
Android shells point their frontend at it, so there's one codebase for the list,
must-do logic, and settings.

## <a id="platforms"></a>Platforms

| Target | Always-on-top | Auto-open schedule | Voice | Reminders | Build |
|---|---|---|---|---|---|
| **macOS** | ✅ native window level | ✅ `launchd` | ✅ `AVSpeechSynthesizer` | — | `apps/macos` |
| **Windows** | ✅ Tauri `alwaysOnTop` | ✅ Task Scheduler | via web | — | `apps/windows` |
| **Android** | ⚠️ overlay (advanced) | — | via web | ✅ scheduled notifications | `apps/android` |
| **Web (PWA)** | ❌ (browser limit) | ❌ (browser limit) | ✅ Web Speech | ⚠️ while open | `apps/web/app` |
| **Chrome extension** | — | — | ✅ Web Speech | ⚠️ while open | `apps/chrome-extension` |
| **Figma / FigJam plugin** | — | — | — | — | `apps/figma-plugin` |
| **Figma / FigJam widget** | — | — | — | — | `apps/figma-widget` |

Web and iOS can't truly float or self-launch — that's an OS limitation, so the
web target is a clean **installable PWA** (offline, add-to-home-screen) and uses
notifications/voice instead of floating. The Chrome extension reuses that same
web UI as a toolbar popup. The Figma **plugin** (personal panel that can stamp
your list onto the canvas) and **widget** (a shared, on-canvas to-do) bring it
into design files.

## <a id="install"></a>Quick start per target

- **macOS** — `cd apps/macos && ./build.sh` → `~/Applications/FloatingTodo.app`. Or grab the [release zip](https://github.com/rakibulism/FloatingTodo/releases/latest).
- **Web** — open `apps/web/app/index.html` over HTTP (it's live on the deployed site at `/app/`), then use your browser's **Install** action.
- **Windows** — `cd apps/windows && cargo tauri build` (see [apps/windows/README.md](apps/windows/README.md)).
- **Android** — `cd apps/android && npm install && npx cap add android` (see [apps/android/README.md](apps/android/README.md)).

## Deploying the site (Vercel)

The deployable site is `apps/web`. In the Vercel project settings set
**Root Directory → `apps/web`** (Framework preset: **Other**, no build command).
Then `/` serves the landing page and `/app/` serves the installable PWA. Every
push to `main` redeploys.
