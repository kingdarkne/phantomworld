-- QBX-native client shims when qbx:enablebridge is false (no QBCore.Functions.SpawnVehicle / GetPlate).
local QBCore = QBCore or {}
QBCore.Functions = QBCore.Functions or {}

QBCore.Functions.Notify = QBCore.Functions.Notify or function(msg, nType, duration)
    lib.notify({ title = 'DMV', description = msg, type = nType or 'inform', duration = duration })
end

QBCore.Functions.GetPlate = QBCore.Functions.GetPlate or function(vehicle)
    if not vehicle or vehicle == 0 then return '' end
    return lib.string.trim(GetVehicleNumberPlateText(vehicle))
end

QBCore.Functions.SpawnVehicle = QBCore.Functions.SpawnVehicle or function(model, cb, coords, isnetworked)
    local modelHash = type(model) == 'string' and joaat(model) or model
    lib.requestModel(modelHash, 10000)
    local x, y, z = coords.x, coords.y, coords.z
    local h = coords.h or coords.w or 0.0
    local veh = CreateVehicle(modelHash, x, y, z, h, isnetworked ~= false, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetModelAsNoLongerNeeded(modelHash)
    if cb then cb(veh) end
end
