local function isAnyAdminOnline()
    local players = GetPlayers()
    for _, pid in ipairs(players) do
        local id = tonumber(pid)
        if id and id > 0 then
            if IsPlayerAceAllowed(pid, 'command') or IsPlayerAceAllowed(pid, 'group.admin') then
                return true
            end
        end
    end
    return false
end

local function sendFallbackReply(source, question)
    local q = question:lower():gsub('%?', '')
    local reply = Config.FallbackReplies['default']
    for keyword, msg in pairs(Config.FallbackReplies) do
        if keyword ~= 'default' and q:find(keyword, 1, true) then
            reply = msg
            break
        end
    end
    TriggerClientEvent('ox_lib:notify', source, { description = reply, type = 'inform', duration = 8000 })
end

local function callOpenAI(question, cb)
    local key = Config.OpenAI and Config.OpenAI.ApiKey or ''
    if key == '' or not key or #key < 10 then
        cb(nil)
        return
    end
    local url = 'https://api.openai.com/v1/chat/completions'
    local body = json.encode({
        model = Config.OpenAI.Model or 'gpt-4o-mini',
        max_tokens = Config.OpenAI.MaxTokens or 200,
        messages = {
            { role = 'system', content = Config.SystemPrompt or 'You are a helpful assistant for a FiveM server.' },
            { role = 'user', content = question }
        }
    })
    PerformHttpRequest(url, function(code, data, headers)
        if code ~= 200 or not data then
            cb(nil)
            return
        end
        local ok, decoded = pcall(json.decode, data)
        if not ok or not decoded or not decoded.choices or not decoded.choices[1] or not decoded.choices[1].message then
            cb(nil)
            return
        end
        cb(decoded.choices[1].message.content or nil)
    end, 'POST', body, { ['Content-Type'] = 'application/json', ['Authorization'] = 'Bearer ' .. key })
end

RegisterNetEvent('aihelp:request', function(question)
    local source = source
    if not question or type(question) ~= 'string' or #question > 500 then
        TriggerClientEvent('ox_lib:notify', source, { description = 'Please keep your question short.', type = 'error', duration = 4000 })
        return
    end

    local useAIOnlyWhenNoAdmin = Config.UseAIOnlyWhenNoAdminOnline
    local adminOnline = isAnyAdminOnline()

    if useAIOnlyWhenNoAdmin and adminOnline then
        TriggerClientEvent('ox_lib:notify', source, { description = 'A staff member is online – try asking in chat or wait for them.', type = 'inform', duration = 6000 })
        return
    end

    local hasApiKey = Config.OpenAI and Config.OpenAI.ApiKey and #Config.OpenAI.ApiKey >= 10
    if hasApiKey then
        callOpenAI(question, function(reply)
            if reply and #reply > 0 then
                TriggerClientEvent('ox_lib:notify', source, { description = reply, type = 'inform', duration = 10000 })
            else
                sendFallbackReply(source, question)
            end
        end)
    else
        sendFallbackReply(source, question)
    end
end)
