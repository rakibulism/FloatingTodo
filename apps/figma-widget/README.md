# Today — Figma / FigJam widget

A live to-do **widget** that lives directly on the canvas in both **Figma** and
**FigJam**. Tasks are stored in the document via `useSyncedState`, so anyone with
the file sees and edits the same list — great for FigJam sessions and project files.

- Type a task in the input and press ⏎ to add it
- Click a row to toggle done (strikethrough)
- **Clear completed** from the widget's property menu (right-click / the ••• menu)

## Plugin vs. widget
- The **widget** (this) is a persistent object on the canvas, shared in the file.
- The **[plugin](../figma-plugin)** is a personal panel (private `clientStorage`) that can also stamp your list onto the canvas.

## Load it (Figma desktop app)
1. **Widgets → Development → Import widget from manifest…**
2. Select `apps/figma-widget/manifest.json`
3. Insert it from the **Widgets → Development** section (or the toolbar widget picker)

No build step: it's plain JS using the widget hyperscript API (`figma.widget.h`),
so `code.js` loads directly with no JSX/TypeScript compilation.

> Written to the standard Figma Widget API; load it in the desktop app to use it.
