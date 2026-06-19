# Windows auto-update (Tauri updater)

The app already **checks for and installs updates silently on launch** (wired in
`src/main.rs` + the `tauri-plugin-updater` dependency). It stays a no-op until you
complete this one-time signing setup — Tauri requires updates to be signed so they
can't be tampered with. No paid account needed; the key is free to generate.

## One-time setup

### 1. Generate an updater key pair
```bash
cargo tauri signer generate -w ~/.tauri/today-updater.key
```
This prints a **public key** and writes a **private key** (keep it secret).

### 2. Add the public key to `src-tauri/tauri.conf.json`
Add a `plugins.updater` block and turn on updater artifacts:
```json
{
  "bundle": { "createUpdaterArtifacts": true },
  "plugins": {
    "updater": {
      "endpoints": [
        "https://github.com/rakibulism/FloatingTodo/releases/latest/download/latest.json"
      ],
      "pubkey": "PASTE_YOUR_PUBLIC_KEY_HERE"
    }
  }
}
```

### 3. Add two GitHub Actions secrets
**Settings → Secrets and variables → Actions:**

| Secret | Value |
|---|---|
| `TAURI_SIGNING_PRIVATE_KEY` | contents of `~/.tauri/today-updater.key` |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | the password you set (blank if none) |

### 4. Add the signing env + `latest.json` publish to the workflow
In `.github/workflows/windows-build.yml`, on the **Build installers** step add:
```yaml
        env:
          TAURI_SIGNING_PRIVATE_KEY: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}
          TAURI_SIGNING_PRIVATE_KEY_PASSWORD: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY_PASSWORD }}
```
With `createUpdaterArtifacts: true`, the build now emits a signed `.msi.zip` + a
`.sig`. Upload those **and** a `latest.json` manifest to the release (the
`tauri-apps/tauri-action` action generates `latest.json` automatically — or build
it from the `.sig` + the release download URL).

## How it behaves once enabled
On each launch the app checks `latest.json`, and if a newer signed version exists
it downloads and installs it silently — users never need to revisit GitHub.

> Until step 2's `createUpdaterArtifacts`/`pubkey` are set, CI builds normally and
> the in-app updater simply finds nothing to do, so nothing breaks in the meantime.
