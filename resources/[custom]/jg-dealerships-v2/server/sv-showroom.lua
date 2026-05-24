Showroom = Showroom or {}

Showroom.Server = Showroom.Server or {}

local vehicleCache = {}

local activeSessions = {}

function Showroom.Server.ClearVehicleCache()

    vehicleCache = {}

end

function Showroom.Server.GetVehicles(dealershipId, forceRefresh)

    if vehicleCache[dealershipId] and not forceRefresh then

        return TableValues(vehicleCache[dealershipId])

    end

    local location = Locations.Server.GetById(dealershipId)

    if not location then

        return false

    end

    if not location.categories or #location.categories == 0 then

        vehicleCache[dealershipId] = {}

        return {}

    end

    local vehicles = MySQL.query.await([[

        SELECT vehicle.*, stock.stock as stock, stock.price as price FROM dealership_vehicles vehicle

        INNER JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle

        INNER JOIN dealership_locations dealership ON stock.dealership = dealership.id

        WHERE vehicle.category IN (?) AND (dealership.id = ?)

        ORDER BY vehicle.spawn_code ASC

    ]], {location.categories, dealershipId})

    vehicleCache[dealershipId] = {}

    for _, vehicle in ipairs(vehicles) do

        vehicleCache[dealershipId][vehicle.spawn_code] = vehicle

    end

    return TableValues(vehicleCache[dealershipId])

end

function Showroom.Server.GetVehicle(dealershipId, vehicleModel, forceRefresh)

    if not vehicleModel or not dealershipId then

        return false

    end

    if vehicleCache[dealershipId] and vehicleCache[dealershipId][vehicleModel] and not forceRefresh then

        return vehicleCache[dealershipId][vehicleModel]

    end

    local location = Locations.Server.GetById(dealershipId)

    if not location then

        return false

    end

    if not location.categories or #location.categories == 0 then

        return false

    end

    local vehicle = MySQL.single.await([[

        SELECT vehicle.*, stock.stock as stock, stock.price as price FROM dealership_vehicles vehicle

        INNER JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle

        INNER JOIN dealership_locations dealership ON stock.dealership = dealership.id

        WHERE vehicle.spawn_code = ? AND dealership.id = ?

        ORDER BY vehicle.spawn_code ASC

    ]], {vehicleModel, dealershipId})

    if vehicleCache[dealershipId] then

        vehicleCache[dealershipId][vehicleModel] = vehicle or nil

    end

    return vehicle or false

end

function Showroom.Server.UpdateVehicleCache(vehicleModel, dealershipId)

    if not dealershipId then

        for dealerId, _ in pairs(vehicleCache) do

            Showroom.Server.GetVehicle(dealerId, vehicleModel, true)

        end

    else

        Showroom.Server.GetVehicle(dealershipId, vehicleModel, true)

    end

end

local function EnterShowroom(playerId, dealershipId, originalCoords)

    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)

    if not playerIdentifier then

        DebugPrint("jg-dealerships:server:enter-showroom: no identifier found for player " .. playerId, "warning")

        return false

    end

    local location = Locations.Server.GetById(dealershipId)

    if not location then

        return false

    end

    local playerJob = Framework.Server.GetPlayerJob(playerId)

    local playerGang = Framework.Server.GetPlayerGang(playerId)

    local hasJobWhitelist = location.showroom_job_whitelist and next(location.showroom_job_whitelist)

    local hasGangWhitelist = location.showroom_gang_whitelist and next(location.showroom_gang_whitelist)

    if hasJobWhitelist or hasGangWhitelist then

        local jobAllowed = false

        if hasJobWhitelist then

            jobAllowed = CheckJobGangWhitelist(location.showroom_job_whitelist, playerJob.name, playerJob.grade)

        end

        local gangAllowed = false

        if hasGangWhitelist then

            gangAllowed = CheckJobGangWhitelist(location.showroom_gang_whitelist, playerGang.name, playerGang.grade)

        end

        if not jobAllowed and not gangAllowed then

            DebugPrint("jg-dealerships:server:enter-showroom: player " .. playerId .. " not allowed in showroom", "debug")

            return false

        end

    end

    local societies = {}

    local hasSocietyJobWhitelist = location.society_purchase_job_whitelist and next(location.society_purchase_job_whitelist)

    local hasSocietyGangWhitelist = location.society_purchase_gang_whitelist and next(location.society_purchase_gang_whitelist)

    if hasSocietyJobWhitelist and playerJob.name then

        if CheckJobGangWhitelist(location.society_purchase_job_whitelist, playerJob.name, playerJob.grade) then

            table.insert(societies, {

                name = playerJob.name,

                label = playerJob.label or playerJob.name,

                type = "job",

                balance = Framework.Server.GetSocietyBalance(playerJob.name, "job")

            })

        end

    end

    if hasSocietyGangWhitelist and playerGang.name then

        if CheckJobGangWhitelist(location.society_purchase_gang_whitelist, playerGang.name, playerGang.grade) then

            table.insert(societies, {

                name = playerGang.name,

                label = playerGang.label or playerGang.name,

                type = "gang",

                balance = Framework.Server.GetSocietyBalance(playerGang.name, "gang")

            })

        end

    end

    local originalBucket = 0

    if Config.ReturnToPreviousRoutingBucket then

        originalBucket = GetPlayerRoutingBucket(playerId)

    end

    activeSessions[playerIdentifier] = {

        dealership = dealershipId,

        originalBucket = originalBucket,

        originalCoords = originalCoords

    }

    local playerPed = GetPlayerPed(playerId)

    ClearPedTasksImmediately(playerPed)

    FreezeEntityPosition(playerPed, true)

    local financedCount = MySQL.scalar.await(

        string.format([[

            SELECT COUNT(*) as total FROM %s

            WHERE financed = 1 AND %s = ?

        ]], Framework.VehiclesTable, Framework.PlayerId),

        {playerIdentifier}

    )

    local maxFinanced = Config.MaxFinancedVehiclesPerPlayer or 999999

    local financeAllowed = financedCount < maxFinanced

    return {

        vehicles = Showroom.Server.GetVehicles(dealershipId),

        financeAllowed = financeAllowed,

        locationData = location,

        societies = societies

    }

end

lib.callback.register("jg-dealerships:server:enter-showroom", EnterShowroom)

lib.callback.register("jg-dealerships:server:check-showroom-whitelist", function(playerId, dealershipId)

    local location = Locations.Server.GetById(dealershipId)

    if not location then

        DebugPrint("[ShowroomWhitelist] Location not found: " .. tostring(dealershipId) .. " - returning true", "debug")

        return true

    end

    local playerJob = Framework.Server.GetPlayerJob(playerId)

    local playerGang = Framework.Server.GetPlayerGang(playerId)

    local hasJobWhitelist = location.showroom_job_whitelist and next(location.showroom_job_whitelist)

    local hasGangWhitelist = location.showroom_gang_whitelist and next(location.showroom_gang_whitelist)

    DebugPrint("[ShowroomWhitelist] Checking access for player " .. playerId .. " at " .. dealershipId, "debug")

    DebugPrint("[ShowroomWhitelist] Player job: " .. tostring(playerJob.name) .. " grade: " .. tostring(playerJob.grade), "debug")

    DebugPrint("[ShowroomWhitelist] Player gang: " .. tostring(playerGang.name) .. " grade: " .. tostring(playerGang.grade), "debug")

    DebugPrint("[ShowroomWhitelist] Job whitelist: " .. json.encode(location.showroom_job_whitelist or {}), "debug")

    DebugPrint("[ShowroomWhitelist] Gang whitelist: " .. json.encode(location.showroom_gang_whitelist or {}), "debug")

    DebugPrint("[ShowroomWhitelist] Has job whitelist: " .. tostring(hasJobWhitelist) .. ", Has gang whitelist: " .. tostring(hasGangWhitelist), "debug")

    if not hasJobWhitelist and not hasGangWhitelist then

        DebugPrint("[ShowroomWhitelist] No whitelists set - allowing access", "debug")

        return true

    end

    local jobAllowed = false

    if hasJobWhitelist then

        jobAllowed = CheckJobGangWhitelist(location.showroom_job_whitelist, playerJob.name, playerJob.grade)

    end

    local gangAllowed = false

    if hasGangWhitelist then

        gangAllowed = CheckJobGangWhitelist(location.showroom_gang_whitelist, playerGang.name, playerGang.grade)

    end

    DebugPrint("[ShowroomWhitelist] Job allowed: " .. tostring(jobAllowed) .. ", Gang allowed: " .. tostring(gangAllowed), "debug")

    DebugPrint("[ShowroomWhitelist] Final result: " .. tostring(jobAllowed or gangAllowed), "debug")

    return jobAllowed or gangAllowed

end)

lib.callback.register("jg-dealerships:server:exit-showroom", function(playerId, data)

    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)

    if not playerIdentifier then

        DebugPrint("jg-dealerships:server:exit-showroom: no identifier found for player " .. playerId, "warning")

        return false

    end

    local playerPed = GetPlayerPed(playerId)

    FreezeEntityPosition(playerPed, false)

    ClearPedTasksImmediately(playerPed)

    activeSessions[playerIdentifier] = nil

    return true

end)
