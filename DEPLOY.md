# Automatic deploy: GitHub → FiveM host

Pushing to the `main` branch triggers [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which SSHes into your game host and runs `git fetch` + `git reset --hard origin/main` in `DEPLOY_PATH`.

**What syncs:** configs, Lua/JS resources, and other tracked files in git.  
**What does not sync:** large assets excluded in [`.gitignore`](.gitignore) (vehicles, clothing, maps, etc.) — upload those once via SFTP/FTP and keep them on the host.

---

## 1. Generate a deploy SSH key (on your PC)

Use a dedicated key — not your personal GitHub key.

```bash
ssh-keygen -t ed25519 -C "github-deploy-phantomworld" -f ~/.ssh/phantomworld_deploy -N ""
```

You will use:

- **Private key** (`~/.ssh/phantomworld_deploy`) → GitHub secret `DEPLOY_SSH_KEY`
- **Public key** (`~/.ssh/phantomworld_deploy.pub`) → host `authorized_keys`

---

## 2. Add the public key on the host

SSH into the VPS (Gravelhost / txAdmin panel terminal, or your own client):

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "PASTE_PUBLIC_KEY_ONE_LINE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Replace `PASTE_PUBLIC_KEY_ONE_LINE` with the contents of `phantomworld_deploy.pub`.

Test from your PC:

```bash
ssh -i ~/.ssh/phantomworld_deploy DEPLOY_USER@135.148.136.32
```

---

## 3. One-time setup on the host

Find your server root. Common paths:

| Host type | Typical path |
|-----------|--------------|
| Pterodactyl / Gravelhost | `/home/container` |
| Bare VPS / txAdmin | `/opt/fivem` or `/home/fivem/server` |

**Clone the repo** into that path (adjust `DEPLOY_PATH`):

```bash
cd /home/container   # or your actual path
git clone https://github.com/kingdarkne/phantomworld.git .
# If the folder already has files, clone to a temp dir and merge, or init:
# git init && git remote add origin https://github.com/kingdarkne/phantomworld.git && git fetch && git checkout -t origin/main
```

**Private repo:** the host must be able to `git fetch`. Either:

- Add a [read-only deploy key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys) on GitHub and put the private key on the host, or  
- Use HTTPS with a fine-scoped PAT:  
  `git remote set-url origin https://<TOKEN>@github.com/kingdarkne/phantomworld.git`

**Restore secrets (never in git):**

```bash
cp mysql.cfg.example mysql.cfg      # edit with real DB credentials
cp secrets.cfg.example secrets.cfg  # edit with sv_licenseKey
```

**Re-add excluded asset folders** (vehicles, clothing, `[defaultmaps]`, etc.) via SFTP — same as manual upload. See [`.gitignore`](.gitignore).

Start the server once manually to confirm everything works before enabling auto-deploy.

---

## 4. GitHub repository secrets

In GitHub: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Required | Example |
|--------|----------|---------|
| `DEPLOY_HOST` | Yes | `135.148.136.32` |
| `DEPLOY_USER` | Yes | `container` or `root` (from your host panel) |
| `DEPLOY_SSH_KEY` | Yes | Full private key file contents (including `-----BEGIN...` / `-----END...` lines) |
| `DEPLOY_PATH` | Yes | `/home/container` or `/opt/fivem` |
| `DEPLOY_RESTART_CMD` | No | Shell command run after sync (host-specific) |

### Optional restart command

Only set `DEPLOY_RESTART_CMD` if you know the exact command on your host. Examples (verify on your panel — do not copy blindly):

```bash
# txAdmin / systemd (example)
systemctl restart fxserver

# Pterodactyl — often restart via panel API or a wrapper script
# touch restart.txt
```

If unset, deploy only updates files; restart the server from txAdmin or your host panel when needed.

---

## 5. Test the pipeline

1. Make a small tracked change (e.g. a comment in a resource).
2. Commit and push to `main`.
3. Open **Actions** on GitHub → **Deploy to FiveM host** → confirm green check.
4. On the host: `cd $DEPLOY_PATH && git log -1 --oneline` should match GitHub.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| SSH connection refused | Check IP, firewall, SSH port (default 22), `DEPLOY_USER` |
| Permission denied (publickey) | Public key not in host `authorized_keys`, or wrong private key in `DEPLOY_SSH_KEY` |
| `No git repo at ...` | Clone repo to `DEPLOY_PATH` (step 3) |
| `git fetch` fails on host | Private repo auth — deploy key or PAT on server |
| Changes not visible in-game | Restart FXServer or set `DEPLOY_RESTART_CMD`; some resources need `ensure` / full restart |

---

## Security notes

- Deploy key on GitHub Actions is **only** for SSH into your VPS — keep it in secrets, never commit it.
- `git reset --hard` on the server discards local edits in tracked files; keep `mysql.cfg`, `secrets.cfg`, and asset folders gitignored.
- Do not store license keys or DB passwords in the repository.
