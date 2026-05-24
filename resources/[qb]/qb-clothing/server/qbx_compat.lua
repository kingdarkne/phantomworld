--- QBCore shim for qbx_core when qb-core bridge is off or unavailable.

local function tryBridge()
    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and obj and obj.Functions and type(obj.Functions.GetPlayer) == 'function' then
        return obj
    end
    return nil
end

local function buildShim()
    assert(GetResourceState('qbx_core') == 'started', '^1[qb-clothing] Start qbx_core before qb-clothing.^0')

    local QBCore = {}
    QBCore.Functions = {}

    function QBCore.Functions.GetPlayer(src)
        return exports.qbx_core:GetPlayer(src)
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

    return QBCore
end

QBCore = tryBridge() or buildShim()
