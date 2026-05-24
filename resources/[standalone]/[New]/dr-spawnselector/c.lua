local Core = nil

local function coreUsesQbFlow()
	return Config.Core == "qb" or Config.Core == "qbx"
end

if Config.Core == "qbx" then
	Core = {
		Functions = {
			GetPlayerData = function(cb)
				local pd = exports.qbx_core:GetPlayerData()
				if type(cb) == "function" then cb(pd) end
				return pd
			end,
		},
	}
end

Citizen.CreateThread(function()
	if Config.Core == "qb" then
		Core = DrGetQBCore()
	elseif Config.Core == "newesx" then
		Core = exports["es_extended"]:getSharedObject()
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                if NetworkIsPlayerActive(PlayerId()) then
                    TriggerEvent('qb-spawn:client:openUI')
                    break
                end
            end
        end)
	end
end)
local weather = "EXTRASUNNY"
local degreeC = 0
local spawnProtectionMs = 8000 -- longer so you don't die from fall damage if Z was wrong

-- Get safe Z on ground so we don't spawn in the air and die
local function GetGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if found then return groundZ end
    return z
end

local function RemoveSpawnProtection(ped)
    if not ped or ped == 0 then return end
    Citizen.CreateThread(function()
        Citizen.Wait(spawnProtectionMs)
        if DoesEntityExist(ped) then
            SetEntityInvincible(ped, false)
            SetEntityCanBeDamaged(ped, true)
        end
    end)
end

RegisterCommand('ss', function()
    local current = GetPlayers()
    local cv = GetConvarInt('sv_maxclients', 32)
    for i = 1, #current do
        current = i
    end
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    if weather == "EXTRASUNNY" or weather == "CLEAR" or weather == "NEUTRAL" then
        degreeC = math.random(20, 30)
    elseif weather == "SMOG" or weather == "FOGGY" or weather == "OVERCAST" or weather == "CLOUDS" or weather == "CLEARING" or weather == "HALLOWEEN" then
        degreeC = math.random(15, 20)
    elseif weather == "RAIN" or weather == "THUNDER" then
        degreeC = math.random(1, 13)
    elseif weather == "SNOW" or weather == "SNOWLIGHT" or weather == "XMAS" or weather == "BLIZZARD" then
        degreeC = math.random(-5, 5)
    end
    if Config.TemperatureType == "f" then
        degreeC = toFahrenheit(degreeC)
    end
    SetNuiFocus(true, true)
    SendNUIMessage({action = "spawnSelector", open = true, resourceName = GetCurrentResourceName(), locations = Config.SpawnCoords, infos = Config.Infos, weatherData = {icon = Config.WeatherIcons[weather], weather = string.lower(weather), tempType = Config.TemperatureType, temp = degreeC, windSpeed = GetWindSpeed(), playerCount = current .. "/" .. cv, time = {hour = hour, minute = minute}}})
end)

function GetPlayers()
    local players = {}
    for i = 0, 256 do
        if NetworkIsPlayerActive(i) then
            players[#players + 1] = i
        end
    end
    return players
end

function toCelsius(f)
    return (f - 32) * 5 / 9
end

function toFahrenheit(c)
    return c * 9 / 5 + 32
end

RegisterNetEvent('qb-spawn:client:openUI', function(value)
    SetEntityVisible(PlayerPedId(), false)
    DoScreenFadeOut(250)
    Citizen.Wait(1000)
    DoScreenFadeIn(250)
    local current = GetPlayers()
    local cv = GetConvarInt('sv_maxclients', 32)
    for i = 1, #current do
        current = i
    end
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    if weather == "EXTRASUNNY" or weather == "CLEAR" or weather == "NEUTRAL" then
        degreeC = math.random(20, 30)
    elseif weather == "SMOG" or weather == "FOGGY" or weather == "OVERCAST" or weather == "CLOUDS" or weather == "CLEARING" or weather == "HALLOWEEN" then
        degreeC = math.random(15, 20)
    elseif weather == "RAIN" or weather == "THUNDER" then
        degreeC = math.random(1, 13)
    elseif weather == "SNOW" or weather == "SNOWLIGHT" or weather == "XMAS" or weather == "BLIZZARD" then
        degreeC = math.random(-5, 5)
    end
    if Config.TemperatureType == "f" then
        degreeC = toFahrenheit(degreeC)
    end
    SetNuiFocus(true, true)
    -- Ensure locations show: send setupLocations if setupSpawns hasn't run yet (e.g. direct openUI)
    SendNUIMessage({action = "setupLocations", locations = Config.SpawnCoords, isNew = false})
    SendNUIMessage({action = "spawnSelector", open = true, resourceName = GetCurrentResourceName(), lastLocation = Config.EnableLastLocation, infos = Config.Infos, weatherData = {icon = Config.WeatherIcons[weather], weather = string.lower(weather), tempType = Config.TemperatureType, temp = degreeC, windSpeed = GetWindSpeed(), playerCount = current .. "/" .. cv, time = {hour = hour, minute = minute}}})
end)

RegisterNetEvent('qb-spawn:client:setupSpawns', function(cData, new, apps)
    if not new then
        SendNUIMessage({
            action = "setupLocations",
            locations = Config.SpawnCoords,
            isNew = new
        })
    elseif new and apps then
        local apartments = {}
        local idx = 0
        for k, v in pairs(apps) do
            local name = v.name or k
            local label = (v and v.label) or tostring(k)
            -- UI position: spread across map (world coords not suitable for %)
            idx = idx + 1
            local row = math.floor((idx - 1) / 3)
            local col = (idx - 1) % 3
            local uiX = 25 + col * 25
            local uiY = 25 + row * 20
            table.insert(apartments, {
                name = name,
                label = label,
                coords = { x = uiX, y = uiY }
            })
        end
        SendNUIMessage({
            action = "setupApartments",
            locations = apartments,
            isNew = new
        })
    end
end)

RegisterNUICallback('spawn', function(data)
    local ped = PlayerPedId()
    if data.type == "lastLocation" then
        if coreUsesQbFlow() then
            PreSpawnPlayer()
            local PlayerData = Core.Functions.GetPlayerData()
            local insideMeta = (PlayerData and PlayerData.metadata) and PlayerData.metadata["inside"] or {}
            Core.Functions.GetPlayerData(function(pd)
                ped = PlayerPedId()
                if not pd or not pd.position then
                    PostSpawnPlayer(ped)
                    return
                end
                local lx, ly, lz = pd.position.x or 0, pd.position.y or 0, pd.position.z or 20.0
                local safeZ = GetGroundZ(lx, ly, lz)
                SetEntityCoords(ped, lx, ly, safeZ)
                SetEntityHeading(ped, pd.position.a or 0.0)
                FreezeEntityPosition(ped, false)
                ClearTimecycleModifier()
                Citizen.CreateThread(function()
                    for _ = 1, 30 do Citizen.Wait(2000) ClearTimecycleModifier() end
                end)
            end)
            if insideMeta and insideMeta.house ~= nil then
                local houseId = insideMeta.house
                TriggerEvent('qb-houses:client:LastLocationHouse', houseId)
            elseif insideMeta.apartment and (insideMeta.apartment.apartmentType ~= nil or insideMeta.apartment.apartmentId ~= nil) then
                local apartmentType = insideMeta.apartment.apartmentType
                local apartmentId = insideMeta.apartment.apartmentId
                TriggerEvent('qb-apartments:client:LastLocationHouse', apartmentType, apartmentId)
            end
            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
            PostSpawnPlayer(ped)
        end
    elseif data.type == "normal" then
        PreSpawnPlayer()
        local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
        if not x or not y or not z then
            PostSpawnPlayer(ped)
            return
        end
        local safeZ = GetGroundZ(x, y, z)
        SetEntityCoords(ped, x, y, safeZ)
        if coreUsesQbFlow() then
            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
            TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        end
        Citizen.Wait(500)
        safeZ = GetGroundZ(x, y, z)
        SetEntityCoords(ped, x, y, safeZ)
        SetEntityHeading(ped, tonumber(data.w) or 0.0)
        ClearTimecycleModifier()
        PostSpawnPlayer(ped)
        Citizen.CreateThread(function()
            for _ = 1, 30 do Citizen.Wait(2000) ClearTimecycleModifier() end
        end)
    elseif data.type == "apartment" then
        local appaYeet = data.name
        local ped = PlayerPedId()
        if ped ~= 0 then
            SetEntityInvincible(ped, true)
            SetEntityCanBeDamaged(ped, false)
        end
        SetNuiFocus(false, false)
        SendNUIMessage({action = "spawnSelector", open = false})
        DoScreenFadeOut(500)
        Citizen.Wait(5000)
        if coreUsesQbFlow() then
            -- Use qb-apartments when started (apartment on join); else ps-housing
            if GetResourceState('qb-apartments') == 'started' then
                local label = (Apartments and Apartments.Locations and Apartments.Locations[appaYeet]) and Apartments.Locations[appaYeet].label or tostring(appaYeet)
                TriggerServerEvent("apartments:server:CreateApartment", appaYeet, label)
            elseif GetResourceState('ps-housing-2.0.7') == 'started' then
                TriggerServerEvent("ps-housing:server:createNewApartment", appaYeet)
            else
                local label = (Apartments and Apartments.Locations and Apartments.Locations[appaYeet]) and Apartments.Locations[appaYeet].label or tostring(appaYeet)
                TriggerServerEvent("apartments:server:CreateApartment", appaYeet, label)
            end
            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
        end
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true)
        ClearTimecycleModifier()
        RemoveSpawnProtection(ped)
        Citizen.CreateThread(function()
            for _ = 1, 30 do Citizen.Wait(2000) ClearTimecycleModifier() end
        end)
    -- elseif data.type == "house" then
    --     PreSpawnPlayer()
    --     TriggerEvent('qb-houses:client:enterOwnedHouse', location)
    --     TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    --     TriggerEvent('QBCore:Client:OnPlayerLoaded')
    --     TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    --     TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    --     PostSpawnPlayer(ped)
    end
end)

function PreSpawnPlayer()
    local ped = PlayerPedId()
    if ped ~= 0 then
        SetEntityInvincible(ped, true)
        SetEntityCanBeDamaged(ped, false)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        FreezeEntityPosition(ped, true)
    end
    SetNuiFocus(false, false)
    SendNUIMessage({action = "spawnSelector", open = false})
    DoScreenFadeOut(500)
    Citizen.Wait(2000)
end

function PostSpawnPlayer(ped)
    if ped and ped ~= 0 then
        FreezeEntityPosition(ped, false)
        SetEntityVisible(PlayerPedId(), true)
        RemoveSpawnProtection(ped)
    end
    Citizen.Wait(500)
    DoScreenFadeIn(250)
end

RegisterNetEvent(Config.WeatherEvent, function(NewWeather, newblackout)
    weather = NewWeather
end)