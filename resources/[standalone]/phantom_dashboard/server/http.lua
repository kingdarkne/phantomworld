--- Lightweight HTTP status API for the Discord bot (requires server HTTP enabled).

local apiToken = Config.Discord.ApiToken
local missingTokenWarned = false

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
    if not apiToken or apiToken == '' then
        if not missingTokenWarned then
            missingTokenWarned = true
            print('[phantom_dashboard] HTTP API disabled: phantom_dashboard:apiToken is not set')
        end
        return false
    end
    return readAuth(req) == apiToken
end

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

    res.writeHead(404, { ['Content-Type'] = 'application/json' })
    res.send(json.encode({ error = 'not_found' }))
end)
