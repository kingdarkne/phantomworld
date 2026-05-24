Framework = nil
PlayerData = {}

Citizen.CreateThread(function()
    for mName, mData in pairs(Config.Locations) do
        if mData.showBlip then
            mData.blipHandle = AddBlipForCoord(mData.blipCoords)
            SetBlipSprite(mData.blipHandle, mData.blipSprite)
            SetBlipColour(mData.blipHandle, mData.blipColor)
            SetBlipScale(mData.blipHandle, 0.8)
            SetBlipAsShortRange(mData.blipHandle, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(mName)
            EndTextCommandSetBlipName(mData.blipHandle)
        end
    end
end)

openBossMenu = function(jobName)
	if Config.Framework == "esx" then
		TriggerEvent("esx_society:openBossMenu", jobName)
	elseif Config.Framework == "qbcore" then
		TriggerEvent("qb-bossmenu:client:OpenMenu")
	end
end

local function refreshPlayerData()
	if not Framework then return end
	if Config.Framework == "esx" then
		PlayerData = Framework.GetPlayerData()
	elseif Config.Framework == "qbcore" then
		PlayerData = Framework.Functions.GetPlayerData()
	end
end

local function isBlockedJob(jobName)
	if not Config.BlockedJobs then return false end
	return Config.BlockedJobs[jobName] == true
end

function hasMechanicJob(jobName)
	refreshPlayerData()
	if not PlayerData or not PlayerData.job then return false end
	local current = PlayerData.job.name
	if isBlockedJob(current) then return false end
	if jobName == "none" or not jobName then return true end
	local required = jobName or Config.MechanicJob or "mechanic"
	if current ~= required then return false end
	if Config.RequireOnDuty and not PlayerData.job.onduty then return false end
	return true
end

local function openKavesMenu(shopName, shopData)
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	if vehicle == 0 then
		ShowNotification("~r~Drive your vehicle into the bay first")
		return
	end
	if shopData.job and shopData.job ~= "none" and not hasMechanicJob(shopData.job) then
		refreshPlayerData()
		if PlayerData and PlayerData.job and Config.BlockedJobs and Config.BlockedJobs[PlayerData.job.name] then
			ShowNotification("~r~Mechanic shops are for the mechanic job only (not staff duty)")
		elseif PlayerData and PlayerData.job and PlayerData.job.name == (Config.MechanicJob or "mechanic") and Config.RequireOnDuty and not PlayerData.job.onduty then
			ShowNotification("~r~Clock in on duty as mechanic first")
		else
			ShowNotification("~r~Mechanic job required")
		end
		return
	end
	if menuOpened then return end
	menuOpened = true
	isIllegalMechanic = shopData.illegalMechanic
	currentMechanic = shopName
	openMechanicMenu(true, vehicle)
end

drawText = function(x, y, z, scale, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 490
    end
end

ShowHelpNotification = function(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

ShowNotification = function(message, flash)
	BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
	EndTextCommandThefeedPostTicker(flash, 1)
end

getVehicleProperties = function(vehicle)
	if DoesEntityExist(vehicle) then
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        if GetIsVehiclePrimaryColourCustom(vehicle) then
            local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
            colorPrimary = {r, g, b}
        end

        if GetIsVehicleSecondaryColourCustom(vehicle) then
            local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
            colorSecondary = {r, g, b}
        end

        local extras = {}
        for extraId = 0, 12 do
            if DoesExtraExist(vehicle, extraId) then
                local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
                extras[tostring(extraId)] = state
            end
        end

        local modLivery = GetVehicleMod(vehicle, 48)
        if GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) ~= 0 then
            modLivery = GetVehicleLivery(vehicle)
        end

        return {
            model = GetEntityModel(vehicle),
            plate = string.gsub(GetVehicleNumberPlateText(vehicle), "^%s*(.-)%s*$", "%1"),
            plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
            dirtLevel = Round(GetVehicleDirtLevel(vehicle), 0.1),
            oilLevel = Round(GetVehicleOilLevel(vehicle), 0.1),
            color1 = colorPrimary,
            color2 = colorSecondary,
            pearlescentColor = pearlescentColor,
            dashboardColor = GetVehicleDashboardColour(vehicle),
            wheelColor = wheelColor,
            wheels = GetVehicleWheelType(vehicle),
            wheelSize = GetVehicleWheelSize(vehicle),
            wheelWidth = GetVehicleWheelWidth(vehicle),
            windowTint = GetVehicleWindowTint(vehicle),
            xenonColor = GetVehicleXenonLightsColour(vehicle),
            neonEnabled = {
                IsVehicleNeonLightEnabled(vehicle, 0),
                IsVehicleNeonLightEnabled(vehicle, 1),
                IsVehicleNeonLightEnabled(vehicle, 2),
                IsVehicleNeonLightEnabled(vehicle, 3)
            },
            neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
            headlightColor = GetVehicleHeadlightsColour(vehicle),
            interiorColor = GetVehicleInteriorColour(vehicle),
            extras = extras,
            tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),
            modSpoilers = GetVehicleMod(vehicle, 0),
            modFrontBumper = GetVehicleMod(vehicle, 1),
            modRearBumper = GetVehicleMod(vehicle, 2),
            modSideSkirt = GetVehicleMod(vehicle, 3),
            modExhaust = GetVehicleMod(vehicle, 4),
            modFrame = GetVehicleMod(vehicle, 5),
            modGrille = GetVehicleMod(vehicle, 6),
            modHood = GetVehicleMod(vehicle, 7),
            modFender = GetVehicleMod(vehicle, 8),
            modRightFender = GetVehicleMod(vehicle, 9),
            modRoof = GetVehicleMod(vehicle, 10),
            modEngine = GetVehicleMod(vehicle, 11),
            modBrakes = GetVehicleMod(vehicle, 12),
            modTransmission = GetVehicleMod(vehicle, 13),
            modHorns = GetVehicleMod(vehicle, 14),
            modSuspension = GetVehicleMod(vehicle, 15),
            modArmor = GetVehicleMod(vehicle, 16),
            modKit17 = GetVehicleMod(vehicle, 17),
            modTurbo = IsToggleModOn(vehicle, 18),
            modKit19 = GetVehicleMod(vehicle, 19),
            modSmokeEnabled = IsToggleModOn(vehicle, 20),
            modKit21 = GetVehicleMod(vehicle, 21),
            modXenon = IsToggleModOn(vehicle, 22),
            modFrontWheels = GetVehicleMod(vehicle, 23),
            modBackWheels = GetVehicleMod(vehicle, 24),
            modCustomTiresF = GetVehicleModVariation(vehicle, 23),
            modCustomTiresR = GetVehicleModVariation(vehicle, 24),
            modPlateHolder = GetVehicleMod(vehicle, 25),
            modVanityPlate = GetVehicleMod(vehicle, 26),
            modTrimA = GetVehicleMod(vehicle, 27),
            modOrnaments = GetVehicleMod(vehicle, 28),
            modDashboard = GetVehicleMod(vehicle, 29),
            modDial = GetVehicleMod(vehicle, 30),
            modDoorSpeaker = GetVehicleMod(vehicle, 31),
            modSeats = GetVehicleMod(vehicle, 32),
            modSteeringWheel = GetVehicleMod(vehicle, 33),
            modShifterLeavers = GetVehicleMod(vehicle, 34),
            modAPlate = GetVehicleMod(vehicle, 35),
            modSpeakers = GetVehicleMod(vehicle, 36),
            modTrunk = GetVehicleMod(vehicle, 37),
            modHydrolic = GetVehicleMod(vehicle, 38),
            modEngineBlock = GetVehicleMod(vehicle, 39),
            modAirFilter = GetVehicleMod(vehicle, 40),
            modStruts = GetVehicleMod(vehicle, 41),
            modArchCover = GetVehicleMod(vehicle, 42),
            modAerials = GetVehicleMod(vehicle, 43),
            modTrimB = GetVehicleMod(vehicle, 44),
            modTank = GetVehicleMod(vehicle, 45),
            modWindows = GetVehicleMod(vehicle, 46),
            modKit47 = GetVehicleMod(vehicle, 47),
            modLivery = modLivery,
            modKit49 = GetVehicleMod(vehicle, 49),
            liveryRoof = GetVehicleRoofLivery(vehicle),
        }
	else
		return
	end
end

setVehicleProperties = function(vehicle, props)
	if DoesEntityExist(vehicle) and props then
        if props.extras then
            for id, enabled in pairs(props.extras) do
                if enabled then
                    SetVehicleExtra(vehicle, tonumber(id), 0)
                else
                    SetVehicleExtra(vehicle, tonumber(id), 1)
                end
            end
        end

        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleModKit(vehicle, 0)
        if props.plate then
            SetVehicleNumberPlateText(vehicle, props.plate)
        end
        if props.plateIndex then
            SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
        end
        if props.fuelLevel then
            SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        end
        if props.dirtLevel then
            SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
        end
        if props.oilLevel then
            SetVehicleOilLevel(vehicle, props.oilLevel)
        end
        if props.color1 then
            if type(props.color1) == "number" then
                ClearVehicleCustomPrimaryColour(vehicle)
                SetVehicleColours(vehicle, props.color1, colorSecondary)
            else
                SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
            end
        end
        if props.color2 then
            if type(props.color2) == "number" then
                ClearVehicleCustomSecondaryColour(vehicle)
                SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
            else
                SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
            end
        end
        if props.pearlescentColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
        end
        if props.interiorColor then
            SetVehicleInteriorColor(vehicle, props.interiorColor)
        end
        if props.dashboardColor then
            SetVehicleDashboardColour(vehicle, props.dashboardColor)
        end
        if props.wheelColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
        end
        if props.wheels then
            SetVehicleWheelType(vehicle, props.wheels)
        end
        if props.windowTint then
            SetVehicleWindowTint(vehicle, props.windowTint)
        end
        if props.windowStatus then
            for windowIndex, smashWindow in pairs(props.windowStatus) do
                if not smashWindow then SmashVehicleWindow(vehicle, windowIndex) end
            end
        end
        if props.doorStatus then
            for doorIndex, breakDoor in pairs(props.doorStatus) do
                if breakDoor then
                    SetVehicleDoorBroken(vehicle, tonumber(doorIndex), true)
                end
            end
        end
        if props.neonEnabled then
            SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
            SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
            SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
            SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
        end
        if props.neonColor then
            SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
        end
        if props.headlightColor then
            SetVehicleHeadlightsColour(vehicle, props.headlightColor)
        end
        if props.interiorColor then
            SetVehicleInteriorColour(vehicle, props.interiorColor)
        end
        if props.wheelSize then
            SetVehicleWheelSize(vehicle, props.wheelSize)
        end
        if props.wheelWidth then
            SetVehicleWheelWidth(vehicle, props.wheelWidth)
        end
        if props.tyreSmokeColor then
            SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
        end
        if props.modSpoilers then
            SetVehicleMod(vehicle, 0, props.modSpoilers, false)
        end
        if props.modFrontBumper then
            SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
        end
        if props.modRearBumper then
            SetVehicleMod(vehicle, 2, props.modRearBumper, false)
        end
        if props.modSideSkirt then
            SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
        end
        if props.modExhaust then
            SetVehicleMod(vehicle, 4, props.modExhaust, false)
        end
        if props.modFrame then
            SetVehicleMod(vehicle, 5, props.modFrame, false)
        end
        if props.modGrille then
            SetVehicleMod(vehicle, 6, props.modGrille, false)
        end
        if props.modHood then
            SetVehicleMod(vehicle, 7, props.modHood, false)
        end
        if props.modFender then
            SetVehicleMod(vehicle, 8, props.modFender, false)
        end
        if props.modRightFender then
            SetVehicleMod(vehicle, 9, props.modRightFender, false)
        end
        if props.modRoof then
            SetVehicleMod(vehicle, 10, props.modRoof, false)
        end
        if props.modEngine then
            SetVehicleMod(vehicle, 11, props.modEngine, false)
        end
        if props.modBrakes then
            SetVehicleMod(vehicle, 12, props.modBrakes, false)
        end
        if props.modTransmission then
            SetVehicleMod(vehicle, 13, props.modTransmission, false)
        end
        if props.modHorns then
            SetVehicleMod(vehicle, 14, props.modHorns, false)
        end
        if props.modSuspension then
            SetVehicleMod(vehicle, 15, props.modSuspension, false)
        end
        if props.modArmor then
            SetVehicleMod(vehicle, 16, props.modArmor, false)
        end
        if props.modKit17 then
            SetVehicleMod(vehicle, 17, props.modKit17, false)
        end
        if props.modTurbo then
            ToggleVehicleMod(vehicle, 18, props.modTurbo)
        end
        if props.modKit19 then
            SetVehicleMod(vehicle, 19, props.modKit19, false)
        end
        if props.modSmokeEnabled then
            ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
        end
        if props.modKit21 then
            SetVehicleMod(vehicle, 21, props.modKit21, false)
        end
        if props.modXenon then
            ToggleVehicleMod(vehicle, 22, props.modXenon)
        end
        if props.xenonColor then
            SetVehicleXenonLightsColor(vehicle, props.xenonColor)
        end
        if props.modFrontWheels then
            SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
        end
        if props.modBackWheels then
            SetVehicleMod(vehicle, 24, props.modBackWheels, false)
        end
        if props.modCustomTiresF then
            SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF)
        end
        if props.modCustomTiresR then
            SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR)
        end
        if props.modPlateHolder then
            SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
        end
        if props.modVanityPlate then
            SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
        end
        if props.modTrimA then
            SetVehicleMod(vehicle, 27, props.modTrimA, false)
        end
        if props.modOrnaments then
            SetVehicleMod(vehicle, 28, props.modOrnaments, false)
        end
        if props.modDashboard then
            SetVehicleMod(vehicle, 29, props.modDashboard, false)
        end
        if props.modDial then
            SetVehicleMod(vehicle, 30, props.modDial, false)
        end
        if props.modDoorSpeaker then
            SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
        end
        if props.modSeats then
            SetVehicleMod(vehicle, 32, props.modSeats, false)
        end
        if props.modSteeringWheel then
            SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
        end
        if props.modShifterLeavers then
            SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
        end
        if props.modAPlate then
            SetVehicleMod(vehicle, 35, props.modAPlate, false)
        end
        if props.modSpeakers then
            SetVehicleMod(vehicle, 36, props.modSpeakers, false)
        end
        if props.modTrunk then
            SetVehicleMod(vehicle, 37, props.modTrunk, false)
        end
        if props.modHydrolic then
            SetVehicleMod(vehicle, 38, props.modHydrolic, false)
        end
        if props.modEngineBlock then
            SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
        end
        if props.modAirFilter then
            SetVehicleMod(vehicle, 40, props.modAirFilter, false)
        end
        if props.modStruts then
            SetVehicleMod(vehicle, 41, props.modStruts, false)
        end
        if props.modArchCover then
            SetVehicleMod(vehicle, 42, props.modArchCover, false)
        end
        if props.modAerials then
            SetVehicleMod(vehicle, 43, props.modAerials, false)
        end
        if props.modTrimB then
            SetVehicleMod(vehicle, 44, props.modTrimB, false)
        end
        if props.modTank then
            SetVehicleMod(vehicle, 45, props.modTank, false)
        end
        if props.modWindows then
            SetVehicleMod(vehicle, 46, props.modWindows, false)
        end
        if props.modKit47 then
            SetVehicleMod(vehicle, 47, props.modKit47, false)
        end
        if props.modLivery then
            SetVehicleMod(vehicle, 48, props.modLivery, false)
            SetVehicleLivery(vehicle, props.modLivery)
        end
        if props.modKit49 then
            SetVehicleMod(vehicle, 49, props.modKit49, false)
        end
        if props.liveryRoof then
            SetVehicleRoofLivery(vehicle, props.liveryRoof)
        end
	end
end

RequestAndWaitModel = function(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(1)
    end
end

RequestAndWaitAnim = function(animDict)
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Citizen.Wait(1)
    end
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Client:SetDuty')
AddEventHandler('QBCore:Client:SetDuty', function()
	refreshPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    TriggerCallback("kaves_mechanic:server:getVehData", function(data)
		if not data then
			return 
		end
		vehData = data
    end)
    PlayerData = Framework.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerCallback("kaves_mechanic:server:getVehData", function(data)
		if not data then
			return
		end
		vehData = data
    end)
    PlayerData = Framework.Functions.GetPlayerData()
end)

Citizen.CreateThread(function()
    if Config.Framework == "esx" then
        Framework = exports["es_extended"]:getSharedObject()
        PlayerData = Framework.GetPlayerData()
        while PlayerData.job == nil do
            PlayerData = Framework.GetPlayerData()
            Citizen.Wait(100)
        end
        TriggerCallback("kaves_mechanic:server:getVehData", function(data)
            if not data then
                return
            end
            vehData = data
        end)
    elseif Config.Framework == "qbcore" then
        Framework = exports['qbx_core']:GetCoreObject()
        refreshPlayerData()
        while not PlayerData or PlayerData.job == nil do
            refreshPlayerData()
            Citizen.Wait(100)
        end
        TriggerCallback("kaves_mechanic:server:getVehData", function(data)
            if data then
                vehData = data
            end
        end)
    else
        print("[KAVES SCRIPTS] FRAMEWORK NOT FOUND!")
    end
end)

-- ox_target + clearer ground markers (server uses ox_target, not qb-target)
CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end
    if not Config.UseOxTarget then return end

    for shopName, shopData in pairs(Config.Locations) do
        for index, coords in ipairs(shopData.coords) do
            exports.ox_target:addSphereZone({
                name = ('kaves_mechanic_%s_%s'):format(shopName, index),
                coords = coords,
                radius = Config.InteractDistance or 3.5,
                debug = false,
                options = {
                    {
                        name = ('kaves_tune_%s_%s'):format(shopName, index),
                        icon = 'fa-solid fa-wrench',
                        label = 'Open Mechanic Menu',
                        distance = 4.0,
                        canInteract = function()
                            return IsPedInAnyVehicle(PlayerPedId(), false)
                                and hasMechanicJob(shopData.job)
                        end,
                        onSelect = function()
                            openKavesMenu(shopName, shopData)
                        end,
                    },
                },
            })
        end

        if shopData.bossMenu and shopData.job and shopData.job ~= 'none' then
            exports.ox_target:addSphereZone({
                name = ('kaves_boss_%s'):format(shopName),
                coords = shopData.bossMenu,
                radius = 2.0,
                debug = false,
                options = {
                    {
                        name = ('kaves_bossmenu_%s'):format(shopName),
                        icon = 'fa-solid fa-clipboard',
                        label = 'Boss Menu',
                        groups = Config.MechanicJob or shopData.job,
                        onSelect = function()
                            openBossMenu(Config.MechanicJob or shopData.job)
                        end,
                    },
                },
            })
        end
    end
end)

-- Brighter markers + ox_lib text when near a bay (in vehicle)
CreateThread(function()
    local drawDist = Config.MarkerDrawDistance or 25.0
    local interactDist = Config.InteractDistance or 3.5
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local pCoords = GetEntityCoords(ped)
            for shopName, shopData in pairs(Config.Locations) do
                for _, mCoords in ipairs(shopData.coords) do
                    local dst = #(pCoords - mCoords)
                    if dst <= drawDist then
                        sleep = 0
                        DrawMarker(1, mCoords.x, mCoords.y, mCoords.z - 0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            2.0, 2.0, 0.5, 0, 204, 102, 180, false, false, 2, false, nil, nil, false)
                        if dst <= interactDist and hasMechanicJob(shopData.job) and not menuOpened then
                            if GetResourceState('ox_lib') == 'started' then
                                lib.showTextUI('[E] Mechanic Menu', { position = 'left-center' })
                            end
                            if IsControlJustPressed(0, 38) then
                                openKavesMenu(shopName, shopData)
                            end
                        end
                    end
                end
            end
        end
        if sleep > 0 and GetResourceState('ox_lib') == 'started' then
            lib.hideTextUI()
        end
        Wait(sleep)
    end
end)

TriggerCallback = function(cbName, cb, data)
    if Config.Framework == "esx" then
        Framework.TriggerServerCallback(cbName, function(output)
            if cb then cb(output) else return output end  
        end, data)
    elseif Config.Framework == "qbcore" then
        Framework.Functions.TriggerCallback(cbName, function(output)
            if cb then cb(output) else return output end  
        end, data)
    end
end