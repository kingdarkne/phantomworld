# Push Phantom World server to GitHub

Remote: https://github.com/kingdarkne/phantomworld

Your full server folder is **~53 GB**. GitHub cannot store that whole tree (100 MB per file, repos should stay near **1 GB** or less).

This repo is set up to commit:

- Configs and custom scripts (`resources/[custom]`, `resources/[qb]`, etc.)
- Server configs, including `secrets.cfg` and `mysql.cfg` (private repo only)

And **exclude**:

- `cache/` (~20 GB)
- `db/` (local embedded database)
- Large vehicle/clothing/map packs (see `.gitignore`)

## Before first push

1. **Install Git** (already at `C:\Program Files\Git\bin\git.exe` — add to PATH if `git` fails in terminal).
2. Ensure `mysql.cfg` and `secrets.cfg` exist at the server root with real credentials and license key.

## After clone on another machine / host

1. Pull or deploy from GitHub — `secrets.cfg` and `mysql.cfg` come with the repo.
2. Re-upload excluded asset folders (vehicles, clothing, etc.) via FTP/SFTP or your host file manager.
3. Start FXServer; run `ensure` resources as in `server.cfg`.
