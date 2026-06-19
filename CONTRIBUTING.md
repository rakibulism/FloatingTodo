# Contributing to Today

Thanks for your interest in improving **Today** — the floating to-do that shows up
so you can't ignore it. Contributions of all kinds are welcome: bug fixes,
features, docs, design, and new platform targets.

By participating you agree to our [Code of Conduct](CODE_OF_CONDUCT.md).

## Ground rules

- **Keep it dependency-light.** The project deliberately ships no frameworks or
  build tooling where it can be avoided. Vanilla JS / native code, please.
- **Change the shared UI once.** The web, Chrome extension, Windows, and Android
  targets all reuse [`apps/web/app`](apps/web/app). Fix UI/logic there, not in N copies.
- **Match the surrounding style.** No formatter is enforced; follow the
  conventions already in the file you're editing.
- **Small, focused PRs** are easier to review and land faster.

## Repo layout

```
apps/
  macos/             native SwiftUI/AppKit app
  web/               landing site (/) + the installable PWA (/app) ← shared UI
  windows/           Tauri shell over apps/web/app
  android/           Capacitor shell over apps/web/app
  chrome-extension/  MV3 popup bundling apps/web/app
  figma-plugin/      Figma + FigJam plugin
  figma-widget/      Figma + FigJam on-canvas widget
```

Each target has its own `README.md` with build/run steps.

## Local development

| Target | How to run |
|---|---|
| Web / PWA | `cd apps/web && python3 -m http.server 8000` → `/` and `/app/` |
| macOS | `cd apps/macos && ./build.sh` |
| Chrome ext | `cd apps/chrome-extension && ./build.sh` → load `dist/` unpacked |
| Windows | `cd apps/windows/src-tauri && cargo tauri dev` (on Windows) |
| Android | `cd apps/android && npm i && npx cap add android && npx cap open android` |
| Figma plugin/widget | Import the `manifest.json` via Figma desktop → Development |

The web app needs to be served over HTTP (service workers + ES modules don't run
over `file://`).

## Pull requests

1. Fork and branch from `main` (`feat/…`, `fix/…`, `docs/…`).
2. Make your change; test the target(s) you touched.
3. Use clear, present-tense commit messages (Conventional Commits style is great:
   `feat(web): …`, `fix(android): …`).
4. Open a PR describing **what** and **why**. Link any related issue.
5. CI builds the Windows and Android targets — keep those green.

## Reporting bugs & ideas

Open a [GitHub issue](https://github.com/rakibulism/FloatingTodo/issues). For bugs,
include your platform, steps to reproduce, and what you expected. For features,
describe the problem you're trying to solve.

## Releases (maintainers)

1. Bump versions where relevant and update the `releases-data` block in
   `apps/web/index.html` (the changelog + the site's "what's new" bell read from it).
2. Push a `vX` tag — the **Windows** and **Android** GitHub Actions build installers
   and attach them to the matching GitHub Release automatically.
3. Add the macOS zip to the release (built locally via `apps/macos/build.sh`).

Thanks for contributing! 💙
