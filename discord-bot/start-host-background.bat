@echo off
cd /d "%~dp0"
if not exist .env (
  echo Create discord-bot\.env with DISCORD_BOT_TOKEN=your_token
  exit /b 1
)
call npm install --omit=dev
if not exist logs mkdir logs
start "PhantomDiscordBot" /MIN cmd /c "node index.js >> logs\bot.log 2>&1"
echo Bot started in background window. Check logs\bot.log
