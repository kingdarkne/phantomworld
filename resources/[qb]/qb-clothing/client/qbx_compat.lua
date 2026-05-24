--- QBCore shim when qb-core bridge is off or unavailable. qb-core is normally provided by qbx_core.

local function tryBridge()
    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and obj and obj.Functions and type(obj.Functions.GetPlayerData) == 'function' then
        return obj
    end
    return nil
end

local function buildShim()
    assert(GetResourceState('qbx_core') == 'started', '^1[qb-clothing] Start qbx_core before qb-clothing.^0')

    local QBCore = {}
    QBCore.Functions = {}
    QBCore.Shared = {
        QBJobsStatus = false,
        SplitStr = function(str, delimiter)
            local r = table.pack(string.strsplit(delimiter, str))
            r.n = nil
            return r
        end,
    }

    function QBCore.Functions.GetPlayerData(cb)
        local pd = exports.qbx_core:GetPlayerData()
        if cb then
            cb(pd)
        else
            return pd
        end
    end

    function QBCore.Functions.TriggerCallback(name, cb, ...)
        local args = { ... }
        CreateThread(function()
            local result = lib.callback.await(name, false, table.unpack(args))
            if cb then cb(result) end
        end)
    end

    function QBCore.Functions.Notify(msg, msgType, duration)
        lib.notify({
            description = tostring(msg),
            type = msgType or 'inform',
            duration = duration or 5000,
        })
    end

    return QBCore
end

QBCore = tryBridge() or buildShim()

--- Works with qb-core DrawText export or ox_lib when bridge is missing.
function QBClothingDrawText(text, position)
    local ok = pcall(function()
        exports['qb-core']:DrawText(text, position or 'left')
    end)
    if ok then return end
    lib.showTextUI(text, {
        position = (position == 'left' or position == nil) and 'left-center' or position,
    })
end

function QBClothingHideText()
    local ok = pcall(function()
        exports['qb-core']:HideText()
    end)
    if ok then return end
    lib.hideTextUI()
end

RegisterNetEvent('QBCore:Client:UpdateObject', function()
    local core = tryBridge()
    if core then
        QBCore = core
    end
end)
