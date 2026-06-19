# Today — Chrome extension

A toolbar popup that reuses the shared web app ([`../web/app`](../web/app)) — your
to-do list and daily must-do tasks, one click away. Manifest V3.

## Build & load
```bash
./build.sh
```
Then in Chrome (or any Chromium browser):
1. Go to `chrome://extensions`
2. Turn on **Developer mode** (top-right)
3. **Load unpacked** → select the generated `dist/` folder

The popup bundles the shared web UI, so tasks persist in the extension's own
storage. Re-run `./build.sh` after editing the web app to refresh the bundle.

## Notes
- `dist/` is generated and gitignored — commit only the source (`manifest.json`, `popup.html`, `build.sh`).
- Publishing to the Chrome Web Store requires a one-time developer account; zip the `dist/` folder and upload it there.
