# aihelp – AI help when no admin is available

Players use **/ask <question>** to get an answer when no staff are online (or you can allow AI to always answer).

## Setup

1. **Optional – OpenAI**
   - Get an API key: https://platform.openai.com/api-keys
   - In `config.lua`, set `Config.OpenAI.ApiKey = 'sk-your-key-here'`
   - Without a key, players get **fallback replies** for keywords (bank, job, garage, etc.)

2. **When the AI is used**
   - `Config.UseAIOnlyWhenNoAdminOnline = true` → AI only when no admin is online.
   - Set to `false` to have AI always answer `/ask`.

3. **Customize**
   - Edit `Config.SystemPrompt` for your server.
   - Edit `Config.FallbackReplies` to add/change keyword answers when no API key is set.

## Command

- **/ask** <question> – Sends the question to the AI (or fallback) and shows the reply in a notification.
