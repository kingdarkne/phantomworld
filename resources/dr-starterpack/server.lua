local function getPlayer(src)
    if GetResourceState('qbx_core') ~= 'started' then return nil end
    return exports['qbx_core']:GetPlayer(src)
end

local function addItem(src, item, count, metadata)
    if not item then return false end

    local timeoutMs = 3000
    local deadline = GetGameTimer() + timeoutMs
    local AddItem = nil

    -- ox_inventory can be "started" before exports are fully ready in some setups.
    while GetGameTimer() < deadline do
        if GetResourceState('ox_inventory') == 'started' then
            local ox = exports['ox_inventory']
            if ox and ox.AddItem then
                AddItem = ox.AddItem
                break
            end
        end
        Wait(100)
    end

    if not AddItem then return false end

    local ok, res = pcall(AddItem, src, item, count or 1, metadata)
    if not ok then
        if lib and lib.print and lib.print.error then
            lib.print.error(('[dr-starterpack] ox_inventory:AddItem failed: %s'):format(res))
        else
            print(('[dr-starterpack] ox_inventory:AddItem failed: %s'):format(res))
        end
        return false
    end

    return res
end

local function giveStarterPack(player, src)
    src = src or (player and player.PlayerData and player.PlayerData.source) or source
    if not src then return end

    local cash = tonumber(Config.Starter.Cash) or 0
    local bank = tonumber(Config.Starter.Bank) or 0
    if cash > 0 then
        player.Functions.AddMoney('cash', cash, 'starter-pack')
    end
    if bank > 0 then
        player.Functions.AddMoney('bank', bank, 'starter-pack')
    end

    -- Starter items
    for _, entry in ipairs(Config.Starter.ExtraItems or {}) do
        addItem(src, entry.name, entry.count or 1, entry.metadata)
    end

    -- Optional starter gun + ammo (disabled when GunItem is nil)
    if Config.Starter.GunItem and Config.Starter.GunItem ~= '' then
        addItem(src, Config.Starter.GunItem, 1, { serie = tostring(math.random(10000000, 99999999)) })
        if Config.Starter.AmmoItem and (tonumber(Config.Starter.AmmoCount) or 0) > 0 then
            addItem(src, Config.Starter.AmmoItem, Config.Starter.AmmoCount, {})
        end
    end

    -- Rank metadata (used by HUD / scripts)
    local level = tonumber(Config.Starter.Level) or 1
    player.Functions.SetMetaData('rank', level)
    player.Functions.SetMetaData('rankxp_level', level)

    -- XNLRankBar (optional): only apply when XP > 0
    local xp = tonumber(Config.Starter.XNLRankXP) or 0
    if GetResourceState('XNLRankBar') == 'started' and xp > 0 then
        local citizenid = player.PlayerData.citizenid
        TriggerEvent('dr-starterpack:server:setXnlXp', citizenid, xp)
        TriggerClientEvent('XNL_NET:XNL_SetInitialXPLevels', src, xp, true, true)
    end

    -- Mark that base starter pack was granted (car is claimed separately)
    player.Functions.SetMetaData('starterpack', true)
    player.Functions.SetMetaData('starterpack_car', false)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Starter Pack',
        description = ('Welcome! +$%s cash, +$%s bank, supplies, and a free starter car (/startercar).'):format(cash, bank),
        type = 'success',
        duration = 10000,
    })
end

local function alreadyClaimed(player)
    local meta = player.PlayerData.metadata or {}
    return meta.starterpack == true
end

local AddonVehicleCache = nil

local function toTitleCase(model)
    model = tostring(model or '')
    model = model:gsub('^%s+', ''):gsub('%s+$', '')
    if model == '' then return model end
    model = model:gsub('[_%-]+', ' ')
    model = model:gsub('(%l)(%u)', '%1 %2')
    model = model:gsub('%s+', ' ')
    return model:gsub('^%l', string.upper)
end

local function parseVehicleMetaForModels(xml)
    local models = {}
    if type(xml) ~= 'string' or xml == '' then return models end
    for modelName in xml:gmatch('<modelName>(.-)</modelName>') do
        modelName = modelName:gsub('%s+', '')
        if #modelName > 0 and #modelName < 64 then
            models[#models + 1] = modelName
        end
    end
    return models
end

local function collectAddonVehiclesOnce()
    if AddonVehicleCache then return AddonVehicleCache end
    local include = Config.Starter.IncludeAddonVehicles
    if include == false then
        AddonVehicleCache = {}
        return AddonVehicleCache
    end

    local seen = {}
    local list = {}

    local num = GetNumResources()
    for i = 0, num - 1 do
        local res = GetResourceByFindIndex(i)
        if res and GetResourceState(res) == 'started' then
            -- common paths for addon vehicles
            local xml = LoadResourceFile(res, 'vehicles.meta')
            if not xml then xml = LoadResourceFile(res, 'data/vehicles.meta') end
            if not xml then xml = LoadResourceFile(res, 'stream/vehicles.meta') end
            if xml and type(xml) == 'string' then
                local models = parseVehicleMetaForModels(xml)
                for j = 1, #models do
                    local model = models[j]
                    local key = model:lower()
                    if not seen[key] then
                        seen[key] = true
                        list[#list + 1] = { label = toTitleCase(model), model = model }
                    end
                end
            end
        end
    end

    -- Merge with configured list later; cache sorted for stable menus
    table.sort(list, function(a, b) return a.label < b.label end)
    AddonVehicleCache = list
    return AddonVehicleCache
end

local function getStarterCarChoices()
    local base = Config.Starter.Cars or {}
    local merged = {}
    local seen = {}

    for i = 1, #base do
        local c = base[i]
        if c and c.model then
            local key = tostring(c.model):lower()
            if not seen[key] then
                seen[key] = true
                merged[#merged + 1] = c
            end
        end
    end

    local addon = collectAddonVehiclesOnce()
    for i = 1, #addon do
        local c = addon[i]
        local key = tostring(c.model):lower()
        if not seen[key] then
            seen[key] = true
            merged[#merged + 1] = c
        end
    end

    return merged
end

local function offerStarterCar(src, player)
    player = player or getPlayer(src)
    if not player then return end
    local meta = player.PlayerData.metadata or {}
    if meta.starterpack_car == true then return end
    local choices = getStarterCarChoices()
    if #choices == 0 then return end
    TriggerClientEvent('dr-starterpack:client:openCarSelect', src, choices)
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end

    CreateThread(function()
        Wait(2500)
        local fresh = getPlayer(src)
        if not fresh then return end

        if not alreadyClaimed(fresh) then
            local ok, err = pcall(function()
                giveStarterPack(fresh, src)
            end)
            if not ok then
                if lib and lib.print and lib.print.error then
                    lib.print.error(('[dr-starterpack] giveStarterPack failed: %s'):format(err))
                else
                    print(('[dr-starterpack] giveStarterPack failed: %s'):format(err))
                end
            end
            Wait(800)
            fresh = getPlayer(src) or fresh
        end

        -- Always offer car picker until claimed (fixes missing openCarSelect)
        offerStarterCar(src, fresh)
    end)
end)

-- Client can request choices anytime (/startercar)
RegisterNetEvent('dr-starterpack:server:requestCarSelect', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end
    local meta = player.PlayerData.metadata or {}
    if meta.starterpack_car == true then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Starter Car',
            description = 'You already claimed your starter car. Visit PDM for more rides.',
            type = 'inform',
        })
        return
    end
    -- Ensure base pack exists so freeroam players are not stuck without cash/phone
    if not alreadyClaimed(player) then
        pcall(function()
            giveStarterPack(player, src)
        end)
        player = getPlayer(src) or player
    end
    offerStarterCar(src, player)
end)

-- Persist XNLRankBar XP to DB (if using XNLRankBar)
AddEventHandler('dr-starterpack:server:setXnlXp', function(citizenid, xp)
    if GetResourceState('XNLRankBar') ~= 'started' then return end
    if GetResourceState('oxmysql') ~= 'started' then return end
    if not citizenid or citizenid == '' then return end
    exports.oxmysql:executeSync(
        'INSERT INTO experience (cid, driving, crafting) VALUES (?, ?, 0) ON DUPLICATE KEY UPDATE driving = ?',
        { citizenid, xp, xp }
    )
end)

RegisterNetEvent('dr-starterpack:server:claimCar', function(model)
    local src = source

    local ok, err = pcall(function()
        local player = getPlayer(src)
        if not player then return end

        local meta = player.PlayerData.metadata or {}
        if meta.starterpack_car == true then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Starter Car',
                description = 'You already claimed your starter car.',
                type = 'error'
            })
            return
        end

        if GetResourceState('qbx_vehicles') ~= 'started' then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Starter Car',
                description = 'Vehicle system not ready yet. Try again in a moment.',
                type = 'error'
            })
            return
        end

        model = tostring(model or '')
        if model == '' then return end

        local allowed = false
        for _, c in ipairs(getStarterCarChoices()) do
            if c.model == model then
                allowed = true
                break
            end
        end
        if not allowed then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Starter Car',
                description = 'That vehicle is not allowed as a starter car.',
                type = 'error'
            })
            return
        end

        local vehicleId, createErr = exports.qbx_vehicles:CreatePlayerVehicle({
            model = model,
            citizenid = player.PlayerData.citizenid,
            garage = Config.Starter.DefaultGarage,
        })
        if not vehicleId then
            if lib and lib.print and lib.print.error then
                lib.print.error(('[dr-starterpack] failed to create vehicle: %s'):format(createErr and createErr.message or 'unknown'))
            else
                print(('[dr-starterpack] failed to create vehicle: %s'):format(createErr and createErr.message or 'unknown'))
            end
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Starter Car',
                description = 'Failed to create your vehicle. Check server console for details.',
                type = 'error'
            })
            return
        end

        player = getPlayer(src) or player
        local vehData = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
        if vehData and vehData.props then
            TriggerClientEvent('dr-starterpack:client:spawnStarterCar', src, model, vehData.props)
        else
            -- still succeeded, but we couldn't fetch props to spawn it
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Starter Car',
                description = ('Your starter car (%s) was added to your garage, but could not be spawned automatically.'):format(model),
                type = 'warning'
            })
        end

        local p2 = getPlayer(src) or player
        p2.Functions.SetMetaData('starterpack_car', true)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Starter Car',
            description = ('Your starter car (%s) is ready.'):format(model),
            type = 'success'
        })
    end)

    if not ok then
        if lib and lib.print and lib.print.error then
            lib.print.error(('[dr-starterpack] claimCar failed: %s'):format(err))
        else
            print(('[dr-starterpack] claimCar failed: %s'):format(err))
        end
        local msg = type(err) == 'string' and err or tostring(err)
        if #msg > 180 then msg = msg:sub(1, 177) .. '...' end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Starter Car',
            description = ('Something went wrong: %s'):format(msg),
            type = 'error',
            duration = 10000,
        })
    end
end)

