# Push Phantom World server to GitHub

Remote: https://github.com/kingdarkne/phantomworld

Your full server folder is **~53 GB**. GitHub cannot store that whole tree (100 MB per file, repos should stay near **1 GB** or less).

This repo is set up to commit:

- Configs and custom scripts (`resources/[custom]`, `resources/[qb]`, etc.)
- Server configs (with secrets excluded)

And **exclude**:

- `cache/` (~20 GB)
- `db/` (local embedded database)
- Large vehicle/clothing/map packs (see `.gitignore`)
- `mysql.cfg` (database password)

## Before first push

1. **Install Git** (already at `C:\Program Files\Git\bin\git.exe` — add to PATH if `git` fails in terminal).
2. **Copy secrets locally** (not in git):
   - `mysql.cfg` — copy from `mysql.cfg.example` and fill in credentials.
   - `secrets.cfg` — copy from `secrets.cfg.example` and add `sv_licenseKey`.

## After clone on another machine / host

1. Copy `mysql.cfg.example` → `mysql.cfg` and set DB string.
2. Copy `secrets.cfg.example` → `secrets.cfg` and set license key.
3. Re-upload excluded asset folders (vehicles, clothing, etc.) via FTP/SFTP or your host file manager.
4. Start FXServer; run `ensure` resources as in `server.cfg`.
