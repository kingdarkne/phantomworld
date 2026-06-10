#!/usr/bin/env bash
cd "$(dirname "$0")"
if [[ -f bot.pid ]]; then
  kill "$(cat bot.pid)" 2>/dev/null && echo "Stopped bot PID $(cat bot.pid)" || echo "Process not running"
  rm -f bot.pid
else
  echo "No bot.pid — bot may not be running in background mode"
fi
