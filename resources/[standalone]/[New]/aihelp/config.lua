Config = {}

-- Set to true to only use AI when no admin is online. When false, AI always answers /ask.
Config.UseAIOnlyWhenNoAdminOnline = true

-- OpenAI API (required for AI replies). Get a key at https://platform.openai.com/api-keys
-- Leave empty to disable AI; players will get a "no staff online" message or keyword replies.
Config.OpenAI = {
    ApiKey = '',  -- e.g. 'sk-...'
    Model = 'gpt-4o-mini',  -- or 'gpt-3.5-turbo' for cheaper
    MaxTokens = 200,
}

-- System prompt so the AI knows it's helping on your server (customize to your server name/rules).
Config.SystemPrompt = [[You are a helpful assistant for a FiveM roleplay server. You help players with in-game questions about jobs, banking, garages, rules, and how to get started. Keep answers short and friendly. If you don't know something, say so and suggest they ask in Discord or wait for staff.]]

-- Optional: simple keyword replies when API key is not set (no cost). Keys are lowercased.
Config.FallbackReplies = {
    ['bank'] = 'Use Phantom Banking at bank blips or ATMs (press E), or open your Phone and tap Welcome Phantom.',
    ['money'] = 'Earn money by doing jobs (get one at City Hall), working at Burger Shot, mechanics, or other businesses.',
    ['job'] = 'Go to City Hall (blip on map) to get a job. You can also apply at businesses like Burger Shot.',
    ['garage'] = 'Drive to a Parking blip on the map and press E to open the garage and take out or store a vehicle.',
    ['car'] = 'Go to a Parking/Garage blip and press E to spawn or store vehicles.',
    ['help'] = 'Press F1 or type /help for the server guide. Use /ask <question> for more help when staff are busy.',
    ['phone'] = 'Press M to open your phone. Use it for banking (Welcome Phantom), messages, and more.',
    ['default'] = 'No staff are available right now. Try /help (F1) for the guide, or ask in Discord. You can also try /ask with a short question.',
}
