# From repo root after git pull on the game host
$botDir = Join-Path $PSScriptRoot '..\discord-bot'
Set-Location $botDir
& (Join-Path $botDir 'start-host.ps1')
