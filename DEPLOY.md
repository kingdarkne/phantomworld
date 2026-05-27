# Automatic deploy: GitHub → FiveM host (SFTP)

Pushing to the `main` branch triggers [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which uploads tracked repo files to your game host over **SFTP** (password auth). Gravelhost and similar Pterodactyl panels often provide SFTP only — no SSH shell — so this workflow syncs files directly instead of running `git pull` on the server.

**What syncs:** configs, Lua/JS resources, and other files tracked in git (same as a fresh checkout of `main`).

**What does not sync:** items listed in [`.gitignore`](.gitignore) — runtime cache, large asset packs (vehicles, clothing, maps, etc.). Upload those once via SFTP and keep them on the host; the workflow will not delete them.

**Secrets:** `secrets.cfg` and `mysql.cfg` are tracked in this private repo and deploy with every push (license key + DB password).

**Restart:** after a successful SFTP upload, the workflow sends a **restart** signal through the Gravelhost/Pterodactyl panel API when the three `PTERODACTYL_*` GitHub secrets are set (see below). SFTP alone cannot restart FXServer.

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
   - **Remote path** — in the panel this is often shown as `/home/container`, but SFTP logins commonly start already inside that directory

Test with FileZilla, WinSCP, or Cyberduck: protocol **SFTP**, same host/port/user/password.

---

## 2. One-time manual setup on the host (via SFTP)

Connect with your SFTP client and upload files the workflow will **never** push from git:

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
| `SFTP_PATH` | No | `.` | Remote server root from the SFTP login; defaults to `.` if unset. If you already set `/home/container` for a Pterodactyl-style host, the workflow maps it to `.` |
| `SFTP_PORT` | No | `2022` | Defaults to `2022` if unset; Gravelhost uses port `2022` |

### Auto-restart after deploy (Gravelhost / Pterodactyl)

SFTP uploads files only; restarting FXServer requires the **panel API**. Add these GitHub secrets:

| Secret | Required for restart | Example | How to get it |
|--------|----------------------|---------|---------------|
| `PTERODACTYL_PANEL_URL` | Yes | `https://panel.gravelhost.com` | Your Gravelhost panel URL (no trailing slash) |
| `PTERODACTYL_CLIENT_API_KEY` | Yes | `ptlc_...` | Gravelhost panel → your account → **API Credentials** → create a **Client API** key with permission to control your server |
| `PTERODACTYL_SERVER_ID` | Yes | `a1b2c3d4-...` | Open your server in the panel; copy the **Server UUID** from the URL or server settings |

After deploy succeeds, the workflow calls `POST /api/client/servers/{id}/power` with `{"signal":"restart"}`. If these secrets are missing, deploy still completes but restart is skipped (warning in the Actions log).

---

## 4. How the workflow works

1. **Checkout** — GitHub Actions checks out `main` (gitignored files are not in the workspace).
2. **Temporary bundle** — stages the checkout in a temp directory outside the repository, using [`.deploy-exclude`](.deploy-exclude) to skip `.git`, cache paths, large asset patterns, and deploy staging artifacts. Includes `secrets.cfg` and `mysql.cfg`.
3. **SFTP upload** — syncs the temp bundle to `SFTP_PATH` with OpenSSH `sftp` (batch mode) and `sshpass` for password auth. Pterodactyl-style `/home/container` paths are treated as the SFTP login root (`.`). No SSH shell required. Job timeout is 120 minutes.
4. **Restart** — if `PTERODACTYL_*` secrets are set, sends a panel API restart signal so FXServer reloads with the new files.

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
| Authentication failed / Permission denied / `GetPass() failed -- assume anonymous login` | Re-copy `SFTP_USER` / `SFTP_PASSWORD` from panel (full password, no truncation); reset password if needed. Password is passed only via the `SSHPASS` env var to `sshpass` (never inline in scripts or URLs), so special characters are supported |
| `protocol: invalid parameter - you provided "sftp"` | Old workflow used FTP-Deploy-Action which only supports FTP/FTPS — current workflow uses OpenSSH `sftp` for true SFTP |
| Files not updating | Confirm workflow succeeded; for Pterodactyl/Gravelhost SFTP, leave `SFTP_PATH` unset or set it to `.` because the login usually starts at the server root |
| `mysql.cfg` / `secrets.cfg` missing on server | Commit them to the private repo and push, or upload manually via SFTP |
| Vehicles/maps missing in-game | Upload excluded asset folders manually via SFTP |
| Changes not visible in-game | Confirm the **Restart game server** step ran; add `PTERODACTYL_*` secrets if restart was skipped |
| Restart failed (HTTP 401/403, not Cloudflare) | Regenerate Client API key; ensure it can control **your** server |
| Restart failed (HTTP 403, “Just a moment…” / Cloudflare) | **Deploy still succeeded.** Gravelhost’s panel blocks GitHub Actions with Cloudflare — restart manually from the panel after deploy, or ask Gravelhost to allow API access from CI |
| Restart failed (HTTP 404) | Wrong `PTERODACTYL_SERVER_ID` — use the full server UUID from the panel URL |

---

## Security notes

- Store SFTP password only in GitHub Actions secrets — never commit it.
- `mysql.cfg` and `secrets.cfg` are in this private GitHub repo and deploy automatically; restrict repo access and disable public forks.
- The workflow uploads tracked code only; it does not wipe manually uploaded assets on the host.
