# Today — Android (Capacitor)

A **Capacitor** shell that wraps the shared web UI ([`../web/app`](../web/app))
into a native Android app, adding **real OS-scheduled notifications** (hourly
reminders that fire even when the app is closed) via `@capacitor/local-notifications`.
The shared UI detects Capacitor at runtime and routes reminders to the native
plugin.

> ⚠️ Not built in this environment — generating the Gradle project and APK
> requires Node, the Android SDK, and Android Studio on your machine. The steps
> below are the standard Capacitor flow.

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
