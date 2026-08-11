# Canvas / Node version crash on KataBump

Panel: https://control.katabump.com/server/22de9d34

If you see:

`NODE_MODULE_VERSION 108` vs `137` / `ERR_DLOPEN_FAILED` on `canvas.node`

the server is running **Node 24** but `canvas` was built for **Node 18**.

## Fix (recommended)

1. KataBump → **Startup** → set **Node.js version** to **18** (or 20).
2. **File Manager** → delete the `node_modules` folder (whole folder).
3. **Console** → **Restart** (panel will run `npm install` again).
4. Wait for install to finish, then confirm `Logged in as …`.

## Alternative (stay on Node 24)

Requires build tools on the host; often fails on game panels:

```bash
rm -rf node_modules
npm install
```

Or set **CUSTOM STARTUP** to:

```bash
npm rebuild canvas --build-from-source && node index.js
```

## Cheerio / `File is not defined` (Node 18)

If you see:

`ReferenceError: File is not defined` in `cheerio` / `undici`

`erela.js-apple` pulls `cheerio: *`, which can install **cheerio 1.2** (needs Node ≥20). The repo pins **cheerio 1.0.0-rc.12** via `package.json` `overrides`.

1. Upload latest `package.json` + `package-lock.json` (deploy script does this).
2. **File Manager** → delete **`node_modules`** (recommended) so `npm install` applies the override.
3. **Startup** → Node **18** → **Restart**.
4. Confirm boot log past `Version 12.0.0 loaded` without crashing.

## npm "deprecated" warnings

Those yellow `npm warn deprecated` lines are normal for this bot stack and are **not** the crash cause.
