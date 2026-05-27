local appliedVehicles = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[phantom_vehicle_balance] %s'):format(message))
    end
end

local function getQbxVehicleData(model)
    if GetResourceState('qbx_core') ~= 'started' then return end

    local ok, data = pcall(function()
        return exports.qbx_core:GetVehiclesByHash(model)
    end)

    if ok and type(data) == 'table' then
        return data
    end
end

local function getBalance(vehicle)
    local class = GetVehicleClass(vehicle)
    if Config.SkipClasses[class] then return end

    local model = GetEntityModel(vehicle)
    local vehicleData = getQbxVehicleData(model)
    local category = vehicleData and vehicleData.category

    if category and Config.CategoryBalance[category] then
        return Config.CategoryBalance[category], category
    end

    return Config.ClassBalance[class], ('class_%s'):format(class)
end

local function applyVehicleBalance(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then return end

    local balance, source = getBalance(vehicle)
    if not balance then return end

    local defaults = appliedVehicles[vehicle]
    if not defaults then
        defaults = {
            maxFlatVel = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel'),
            driveForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce'),
        }
        appliedVehicles[vehicle] = defaults
    end

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', defaults.maxFlatVel * balance.maxSpeed)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', defaults.driveForce * balance.driveForce)

    debugPrint(('applied %s to %s: speed %.2f, force %.2f'):format(
        source,
        GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
        balance.maxSpeed,
        balance.driveForce
    ))
end

local function applyCurrentVehicle()
    if cache.vehicle and cache.seat == -1 then
        applyVehicleBalance(cache.vehicle)
    end
end

lib.onCache('vehicle', function(vehicle)
    if not vehicle then return end

    SetTimeout(250, applyCurrentVehicle)
end)

lib.onCache('seat', function(seat)
    if seat ~= -1 then return end

    SetTimeout(250, applyCurrentVehicle)
end)

CreateThread(function()
    while true do
        Wait(5000)
        applyCurrentVehicle()
    end
end)
