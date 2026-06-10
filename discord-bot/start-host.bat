@echo off
cd /d "%~dp0"
if not exist .env (
  echo Create discord-bot\.env with DISCORD_BOT_TOKEN=your_token
  exit /b 1
)
where node >nul 2>&1 || (
  echo Install Node.js 18+ and restart the panel/SSH session.
  exit /b 1
)
call npm install --omit=dev
echo Starting Phantom World Discord bot...
node index.js
