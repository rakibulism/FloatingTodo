# Today — Android (Capacitor)

A **Capacitor** shell that wraps the shared web UI ([`../web/app`](../web/app))
into a native Android app, adding **real OS-scheduled notifications** (hourly
reminders that fire even when the app is closed) via `@capacitor/local-notifications`.
The shared UI detects Capacitor at runtime and routes reminders to the native
plugin.

> 💡 **No Android toolchain locally? Use CI.** The
> [`Android build`](../../.github/workflows/android-build.yml) GitHub Action
> scaffolds the native project and assembles a debug `.apk` on an Ubuntu runner.
> Trigger it from the **Actions** tab → *Android build* → *Run workflow* (the APK
> appears as an artifact), or push a `v*` tag to also attach it to the Release.
> (Debug-signed; a Play-ready release build needs a signing keystore.)
>
> The steps below are for building locally.

## Build
```bash
cd apps/android
npm install
npx cap add android      # generates the native android/ project (gitignored)
npx cap copy             # copies ../web/app into the native project
npx cap open android     # opens Android Studio → Run / build APK
```
`webDir` is set to `../web/app` in `capacitor.config.json`, so the app always
bundles the current shared UI. Re-run `npx cap copy` after editing the web app.

## Notes
- **Reminders**: enable in the app's Settings → grants notification permission and schedules an hourly reminder.
- **Always-on-top**: Android can draw over other apps only with the `SYSTEM_ALERT_WINDOW` ("display over other apps") permission and a foreground service — that's an advanced native addition, not included in this thin shell.
- `node_modules/` and the generated `android/` folder are gitignored.
