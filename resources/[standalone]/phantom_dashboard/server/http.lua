--- Lightweight HTTP status API for the Discord bot (requires server HTTP enabled).
--- NOTE: screencapture also calls SetHttpHandler and usually wins. Prefer the
--- proxied routes added in screencapture (GET /phantom-dashboard/*). This file still
--- mounts a handler and periodically reclaims as a fallback when screencapture is stopped.

local apiToken = Config.Discord.ApiToken

local function unauthorized(res)
    res.writeHead(401, { ['Content-Type'] = 'application/json' })
    res.send(json.encode({ error = 'unauthorized' }))
end

local function readAuth(req)
    local header = req.headers and req.headers['Authorization']
    if header and header:sub(1, 7) == 'Bearer ' then
        return header:sub(8)
    end
    return req.headers and req.headers['X-Phantom-Token']
end

local function authorized(req)
    if not apiToken or apiToken == '' then return true end
    return readAuth(req) == apiToken
end

local function mountHandler()
    SetHttpHandler(function(req, res)
        if req.method == 'OPTIONS' then
            res.writeHead(204, {
                ['Access-Control-Allow-Origin'] = '*',
                ['Access-Control-Allow-Methods'] = 'GET, OPTIONS',
                ['Access-Control-Allow-Headers'] = 'Authorization, X-Phantom-Token',
            })
            res.send('')
            return
        end

        if req.method ~= 'GET' then
            res.writeHead(405, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({ error = 'method_not_allowed' }))
            return
        end

        if not authorized(req) then
            unauthorized(res)
            return
        end

        local path = req.path or '/'

        if path == '/phantom-dashboard/status' or path == '/status' then
            local status = exports[GetCurrentResourceName()]:GetStatus()
            res.writeHead(200, {
                ['Content-Type'] = 'application/json',
                ['Access-Control-Allow-Origin'] = '*',
            })
            res.send(json.encode(status))
            return
        end

        if path == '/phantom-dashboard/players' or path == '/players' then
            local players = exports[GetCurrentResourceName()]:GetPlayers()
            res.writeHead(200, {
                ['Content-Type'] = 'application/json',
                ['Access-Control-Allow-Origin'] = '*',
            })
            res.send(json.encode({ players = players, count = #players }))
            return
        end

        if path == '/phantom-dashboard/events' or path == '/events' then
            local events = exports[GetCurrentResourceName()]:GetRecentEvents()
            res.writeHead(200, {
                ['Content-Type'] = 'application/json',
                ['Access-Control-Allow-Origin'] = '*',
            })
            res.send(json.encode({ events = events, count = #events }))
            return
        end

        -- Pass-through style 404 for unknown routes (other tools may expect this).
        res.writeHead(404, { ['Content-Type'] = 'application/json' })
        res.send(json.encode({ error = 'not_found', path = path }))
    end)
end

mountHandler()

-- Win the SetHttpHandler race against runcode / late resources.
CreateThread(function()
    for _, waitMs in ipairs({ 2000, 8000, 20000 }) do
        Wait(waitMs)
        mountHandler()
    end
    print('[phantom_dashboard] HTTP status API mounted (reclaimed SetHttpHandler)')
    while true do
        Wait(45000)
        mountHandler()
    end
end)
