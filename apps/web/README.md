# Today — web (landing + PWA)

This is the deployable site and the **shared web UI**.

```
apps/web/
├── index.html          marketing landing page  (served at /)
├── assets/             og image, icon, favicon
├── app/                the installable PWA      (served at /app/)
│   ├── index.html
│   ├── core.js         shared todo + must-do data model
│   ├── ui.js           rendering, voice, install, notifications
│   ├── app.css
│   ├── manifest.webmanifest
│   ├── sw.js           offline service worker
│   └── icons/
└── tools/make_web_assets.swift   regenerates assets/
```

`app/` is reused verbatim by the **Windows** (Tauri) and **Android** (Capacitor)
shells — keep platform-specific code out of it; it feature-detects the shell at
runtime (`window.__TAURI__`, `window.Capacitor`).

## Run locally
PWAs need HTTP (service workers + ES modules don't work over `file://`):
```bash
cd apps/web && python3 -m http.server 8000
# landing → http://localhost:8000/   ·   app → http://localhost:8000/app/
```

## The PWA
- Todos, daily must-do tasks (reset each calendar day), and settings — stored in `localStorage`.
- **Installable** (manifest + service worker): use the in-app Install banner, or your browser's install action / "Add to Home Screen".
- **Voice**: the speaker button reads your pending count aloud (Web Speech API, male voice).
- **Reminders**: optional hourly notifications while the tab is open. (Background scheduling and floating-on-top are OS-only — see the native macOS/Windows apps.)

## Deploy (Vercel)
Set the Vercel project **Root Directory → `apps/web`**, Framework preset **Other**,
no build command. `/` is the landing page, `/app/` is the PWA.
