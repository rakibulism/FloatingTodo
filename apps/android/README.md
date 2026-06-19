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

## Signed release builds (CI)

The Android workflow builds a **signed release APK** when four repo secrets are
present (otherwise it falls back to a debug APK). Signing keys are yours to own —
generate them locally and add them as secrets; never commit a keystore.

```bash
# 1) Create a keystore (keep this file safe + private; do NOT commit it)
keytool -genkeypair -v -keystore today-release.jks \
  -alias today -keyalg RSA -keysize 2048 -validity 10000

# 2) Base64-encode it for the secret
base64 -i today-release.jks | pbcopy   # macOS: now on your clipboard
```

Then add these in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the base64 from step 2 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password you chose |
| `ANDROID_KEY_ALIAS` | `today` (or your alias) |
| `ANDROID_KEY_PASSWORD` | key password you chose |

Re-run the **Android build** workflow (or push a new tag) and it will produce a
signed `app-release.apk`. ⚠️ Keep `today-release.jks` and its passwords backed up
— losing them means you can't ship updates under the same app identity.

## Notes
- **Voice**: Android's WebView doesn't support the Web Speech API, so the app speaks via the native [`@capacitor-community/text-to-speech`](https://github.com/capacitor-community/text-to-speech) plugin (the shared UI auto-detects Capacitor and routes to it). Run `npx cap sync` after `npm install` so the native plugin is wired in.
- **Reminders**: enable in the app's Settings → grants notification permission and schedules an hourly reminder.
- **Always-on-top**: Android can draw over other apps only with the `SYSTEM_ALERT_WINDOW` ("display over other apps") permission and a foreground service — that's an advanced native addition, not included in this thin shell.
- `node_modules/` and the generated `android/` folder are gitignored.
