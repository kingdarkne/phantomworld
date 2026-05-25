# Automatic deploy: GitHub → FiveM host (SFTP)

Pushing to the `main` branch triggers [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which uploads tracked repo files to your game host over **SFTP** (password auth). Gravelhost and similar Pterodactyl panels often provide SFTP only — no SSH shell — so this workflow syncs files directly instead of running `git pull` on the server.

**What syncs:** configs, Lua/JS resources, and other files tracked in git (same as a fresh checkout of `main`).

**What does not sync:** items listed in [`.gitignore`](.gitignore) — runtime cache, secrets, large asset packs (vehicles, clothing, maps, etc.). Upload those once via SFTP and keep them on the host; the workflow will not delete them.

**Restart:** the workflow does not restart FXServer. After deploy, restart from the Gravelhost panel or txAdmin when needed.

---

## 1. SFTP credentials (Gravelhost panel)

1. Log in to the [Gravelhost](https://gravelhost.com) game panel.
2. Open your **FiveM / txAdmin** server.
3. Go to **Settings → SFTP Details** (or **File Manager → SFTP**).
4. Note:
   - **Host** (server IP or SFTP hostname)
   - **Port** (often `2022` on Gravelhost; default SSH is `22`)
   - **Username** (usually something like `container.xxxxx`)
   - **Password** (panel-generated; reset there if lost)
   - **Remote path** — server root is typically `/home/container`

Test with FileZilla, WinSCP, or Cyberduck: protocol **SFTP**, same host/port/user/password.

---

## 2. One-time manual setup on the host (via SFTP)

Connect with your SFTP client and upload files the workflow will **never** push from git:

### Secrets (required once)

Copy the example templates from the repo, edit with real values, upload to the server root:

| Local (from repo) | Upload to server as | Contents |
|-------------------|---------------------|----------|
| `mysql.cfg.example` | `mysql.cfg` | Database credentials |
| `secrets.cfg.example` | `secrets.cfg` | `sv_licenseKey` and other server secrets |

**Never commit** `mysql.cfg` or `secrets.cfg` to GitHub.

### Large asset folders (manual once)

Re-upload via SFTP after first clone — see [`.gitignore`](.gitignore). Examples:

- `resources/[vehicles]/`
- `resources/[clothing]/`
- `resources/[defaultmaps]/`
- `resources/[Graphics]/`
- Other paths excluded in `.gitignore`

The deploy workflow **overwrites matching paths** but does **not** delete extra files on the server, so manually uploaded assets stay in place.

Start the server once from the panel to confirm everything works before relying on auto-deploy.

---

## 3. GitHub repository secrets

In GitHub: **Settings → Secrets and variables → Actions → New repository secret**

Remove old SSH deploy secrets if you used them: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PATH`, `DEPLOY_RESTART_CMD`.

| Secret | Required | Example | Notes |
|--------|----------|---------|-------|
| `SFTP_HOST` | Yes | `135.148.136.32` | From panel SFTP details |
| `SFTP_USER` | Yes | `container.abc123` | SFTP username |
| `SFTP_PASSWORD` | Yes | *(panel password)* | Paste the **full** panel password exactly; `@`, `.`, and other special characters are supported |
| `SFTP_PATH` | No | `/home/container` | Remote server root; defaults to `/home/container` if unset |
| `SFTP_PORT` | No | `2022` | Defaults to `22` if unset; Gravelhost often uses `2022` |

---

## 4. How the workflow works

1. **Checkout** — GitHub Actions checks out `main` (gitignored files are not in the workspace).
2. **Rsync filter** — excludes `.git`, secrets, cache paths, and large asset patterns (mirrors [`.gitignore`](.gitignore)).
3. **SFTP upload** — syncs filtered files to `SFTP_PATH` with `lftp mirror -R` over SFTP (password via `sshpass` + `SSHPASS` env var; no SSH shell required).

---

## 5. Test the pipeline

1. Add the GitHub secrets above.
2. Make a small tracked change (e.g. a comment in a resource).
3. Commit and push to `main`.
4. Open **Actions** on GitHub → **Deploy to FiveM host** → confirm a green check.
5. Connect via SFTP and verify the changed file updated on the host.
6. Restart the server from the panel if the change requires it.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Connection timed out | Check `SFTP_HOST`, `SFTP_PORT` (try `2022` for Gravelhost), firewall |
| Authentication failed / Permission denied | Re-copy `SFTP_USER` / `SFTP_PASSWORD` from panel (full password, no truncation); reset password if needed. Passwords with `@` or `$` must be stored exactly in GitHub Secrets — the workflow passes them via `SSHPASS`, not unquoted shell args |
| Files not updating | Confirm workflow succeeded; check `SFTP_PATH` points at server root |
| `mysql.cfg` / `secrets.cfg` missing on server | Upload manually via SFTP (never in git) |
| Vehicles/maps missing in-game | Upload excluded asset folders manually via SFTP |
| Changes not visible in-game | Restart FXServer from Gravelhost / txAdmin |

---

## Security notes

- Store SFTP password only in GitHub Actions secrets — never commit it.
- `mysql.cfg`, `secrets.cfg`, license keys, and DB passwords stay off GitHub; maintain them on the server via SFTP.
- The workflow uploads tracked code only; it does not wipe manually uploaded assets on the host.
