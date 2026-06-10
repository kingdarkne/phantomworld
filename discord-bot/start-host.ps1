# Run on the game server host (same machine as FXServer)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Test-Path '.env')) {
    Write-Host 'Create discord-bot/.env with DISCORD_BOT_TOKEN=your_token'
    exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host 'Node.js 18+ required on the host.'
    exit 1
}

npm install --omit=dev
Write-Host 'Starting Phantom World Discord bot (relay on 127.0.0.1:3099)...'
node index.js
