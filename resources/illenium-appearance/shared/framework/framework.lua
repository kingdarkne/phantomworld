Framework = {}

function Framework.ESX()
    return GetResourceState("es_extended") ~= "missing"
end

function Framework.QBCore()
    -- Must be actually running — "stopped" qb-core folder still exists on disk.
    return GetResourceState("qbx_core") == "started"
        or GetResourceState("qb-core") == "started"
end

function Framework.Ox()
    return GetResourceState("ox_core") ~= "missing"
end
