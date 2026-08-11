# Phantom Rex AI (local)

Local drop-in for the offline Rex host (`23.238.64.91:5600`).

## What it does
- `POST /chat` — Groq LLM + **live web search** + Edge/Google TTS → `{ reply_text, audio_url }`
- `POST /transcribe` — Groq Whisper STT
- `POST /tts` / `POST /synthesize` — TTS for `$say` / Rex speak
- `POST /mode` / `POST /reset` — per-guild memory + unrestricted flag

## Live web (Copilot-style)
On current-events questions (`who is`, `today`, `president`, `price`, …) Rex fetches:
DuckDuckGo HTML (+ lite fallback), Wikipedia (incl. incumbent infobox), DuckDuckGo Instant,
and optionally **Brave Search** if `BRAVE_SEARCH_API_KEY` is set.

Env:
- `REX_WEB_SEARCH=auto` (default) | `always` | `off`
- `BRAVE_SEARCH_API_KEY` — optional, stronger results

## Run on VPS
```bash
# Deploy script installs the unit and rewrites REX_API_URL to localhost
systemctl status phantom-rex-ai
curl -s http://127.0.0.1:5600/health
```

Requires `GROQ` (or `GROQ_API_KEY`) in `/home/phantom_bot/.env`.
