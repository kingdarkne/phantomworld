@echo off
setlocal enabledelayedexpansion

:: Prompt for version number
set /p version="Enter version number (e.g., 1.0.0): "

:: Update fxmanifest.lua
powershell -Command "(Get-Content fxmanifest.lua) -replace \"version\s+'[\d\.]+'\", \"version '!version!'\" | Set-Content fxmanifest.lua"

:: Build web directory
cd web
call pnpm install
call pnpm build
cd ..

:: Stage all changes (including untracked files)
git add .

:: Commit all changes
git commit -m "Release version v%version%"

:: Create and push Git tag
git tag v%version%
git push origin main
git push origin v%version%

echo Release v%version% created and pushed to GitHub.
pause