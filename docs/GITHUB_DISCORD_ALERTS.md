# GitHub push → Discord alerts

Git pushes do **not** notify Discord automatically. Enable this workflow:

1. GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. New secret: `DISCORD_WEBHOOK` = your full webhook URL (same as in `phantom_dashboard.secrets.cfg`)
3. Push to `main` — workflow `.github/workflows/discord-push.yml` posts to that channel

You will also get a **DM** if the Discord **bot runs on the game host** and mirrors webhook channel events (optional).
