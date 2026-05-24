-- Register /ask command: players can type /ask <question> when no admin is free
RegisterCommand('ask', function(_, rawArgs)
    local question = rawArgs and rawArgs:match('^%s*(.-)%s*$') or ''
    if question == '' then
        lib.notify({ description = 'Usage: /ask <your question>', type = 'inform', duration = 5000 })
        return
    end
    TriggerServerEvent('aihelp:request', question)
end, false)

TriggerEvent('chat:addSuggestion', '/ask', 'Ask the AI assistant when no admin is available', {
    { name = 'question', help = 'Your question (e.g. How do I get a job?)' }
})
