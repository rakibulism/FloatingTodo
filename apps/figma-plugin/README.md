# Today — Figma / FigJam plugin

A to-do plugin that runs in both **Figma** and **FigJam**. Manage your tasks and
daily must-dos in the plugin window, and drop the list onto the canvas — as
**sticky notes** in FigJam, or a **text frame** in Figma.

- `manifest.json` — plugin manifest (`editorType: ["figma", "figjam"]`)
- `code.js` — main thread: `clientStorage` persistence + canvas insert
- `ui.html` — self-contained plugin UI (no build step, no network)

## Load it (Figma desktop app)
1. **Plugins → Development → Import plugin from manifest…**
2. Select `apps/figma-plugin/manifest.json`
3. Run it from **Plugins → Development → Today**

No build step — it's plain JS/HTML. Tasks persist per-user via `figma.clientStorage`.

> Written to the standard Figma Plugin API; not run inside Figma in this repo's
> CI. Load it in the desktop app to use it.
