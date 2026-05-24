local isServer = IsDuplicityVersion()

-- Minimal QBCore compatibility layer for dr-admin on QBX.
-- This lets dr-admin run without qb-core or the qbx qb-bridge.
QBCore = QBCore or {}
QBCore.Functions = QBCore.Functions or {}
QBCore.Commands = QBCore.Commands or {}
QBCore.Shared = QBCore.Shared or {}

if not lib then
    return
end

if isServer then
    local function getPlayer(src)
        if GetResourceState('qbx_core') ~= 'started' then return nil end
        return exports.qbx_core:GetPlayer(src)
    end

    local function getIdentifier(src, idType)
        idType = tostring(idType or ''):lower()
        return GetPlayerIdentifierByType(src, idType)
    end

    local function hasPerm(src, perm)
        perm = tostring(perm or ''):lower()
        -- treat admin/god the same: ace based
        if perm == 'admin' or perm == 'god' then
            return IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'easyadmin')
        end
        return IsPlayerAceAllowed(src, perm)
    end

    function QBCore.Functions.GetPlayer(src)
        return getPlayer(src)
    end

    function QBCore.Functions.GetPlayers()
        return GetPlayers()
    end

    function QBCore.Functions.GetIdentifier(src, idType)
        return getIdentifier(src, idType)
    end

    function QBCore.Functions.GetPermission(src)
        -- Return a single string group that dr-admin expects sometimes.
        if hasPerm(src, 'god') then return 'god' end
        if hasPerm(src, 'admin') then return 'admin' end
        return 'user'
    end

    function QBCore.Functions.CreateCallback(name, cb)
        lib.callback.register(name, function(source, ...)
            local p = promise.new()
            cb(source, function(...)
                p:resolve(table.pack(...))
            end, ...)
            local packed = Citizen.Await(p)
            return table.unpack(packed, 1, packed.n)
        end)
    end

    function QBCore.Commands.Add(name, help, arguments, _, handler, permission)
        RegisterCommand(name, function(source, args, raw)
            if permission and source > 0 and not hasPerm(source, permission) then
                return
            end
            handler(source, args, raw)
        end, false)
    end

    -- Shared data (best-effort)
    local okItems, oxItems = pcall(require, '@ox_inventory.data.items')
    if okItems and type(oxItems) == 'table' then
        QBCore.Shared.Items = oxItems
    end
    QBCore.Shared.Jobs = exports.qbx_core:GetJobs()
    QBCore.Shared.Gangs = exports.qbx_core:GetGangs()
    QBCore.Shared.Vehicles = QBCore.Shared.Vehicles or {}
else
    local function notify(text, nType, duration)
        local description = text
        local title
        if type(text) == 'table' then
            title = text.text
            description = text.caption
        end
        lib.notify({
            title = title,
            description = description,
            type = nType or 'inform',
            duration = duration or 5000,
        })
    end

    function QBCore.Functions.Notify(text, nType, duration)
        notify(text, nType, duration)
    end

    RegisterNetEvent('QBCore:Notify', function(text, nType, duration)
        notify(text, nType, duration)
    end)

    function QBCore.Functions.GetPlayerData()
        if GetResourceState('qbx_core') ~= 'started' then return {} end
        return exports.qbx_core:GetPlayerData() or {}
    end

    function QBCore.Functions.TriggerCallback(name, cb, ...)
        local packed = table.pack(...)
        CreateThread(function()
            local result = table.pack(lib.callback.await(name, false, table.unpack(packed, 1, packed.n)))
            if cb then cb(table.unpack(result, 1, result.n)) end
        end)
    end

    function QBCore.Functions.LoadModel(model)
        model = type(model) == 'string' and joaat(model) or model
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end

    function QBCore.Functions.GetClosestVehicle(coords)
        coords = coords or GetEntityCoords(PlayerPedId())
        local vehicles = GetGamePool('CVehicle')
        local closest, closestDist = 0, 999999.0
        for i = 1, #vehicles do
            local veh = vehicles[i]
            local dist = #(GetEntityCoords(veh) - coords)
            if dist < closestDist then
                closestDist = dist
                closest = veh
            end
        end
        return closest, closestDist
    end

    -- Shared (best-effort)
    QBCore.Shared.Jobs = exports.qbx_core:GetJobs()
    QBCore.Shared.Gangs = exports.qbx_core:GetGangs()
    -- Newer qbx_core builds may not expose GetVehicles; keep admin menu alive with fallback.
    local okVehicles, vehicles = pcall(function()
        return exports.qbx_core:GetVehicles()
    end)
    QBCore.Shared.Vehicles = okVehicles and vehicles or {}
end

