# Voice channel AI assistant

Talk with the bot in voice — it answers out loud and can sound like different people.

## Setup

1. Add to `.env` on KataBump:

```env
OPENAI_API_KEY=sk-...
```

2. Bot needs **Connect**, **Speak**, and **Use Voice Activity** permissions.

3. Restart the server after deploy.

## Commands

| Command | What it does |
|---------|----------------|
| `/vcjoin` | Bot joins your voice channel (stops music if playing) |
| `/ask question:…` | Anyone in the same VC gets a spoken answer |
| Speak in VC | After `/vcjoin`, bot listens and responds (Whisper + TTS) |
| `/vcvoice persona:…` | Pick voice: Jenny, Ryan, Pirate, Robot, etc. |
| `/vcpersona style:…` | e.g. `southern cowboy` or `wise old wizard` |
| `/vclisten enabled:true/false` | Toggle listening without `/ask` |
| `/vcleave` | Bot leaves voice |

## Personas (`/vcvoice`)

- Default assistant, Jenny, Ryan, Grandpa, Coach, Robot, Pirate, Narrator

Each persona uses a different OpenAI TTS voice + personality. `/vcpersona` adds extra style on top.

## Notes

- Answers are kept short for speech (1–3 sentences).
- Text replies also appear in the channel when someone speaks in VC.
- Music and voice AI cannot run at the same time — `/vcjoin` stops music.
