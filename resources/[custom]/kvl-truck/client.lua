ESX = exports["es_extended"]:getSharedObject()


function DrawText3D(msg, coords)
    AddTextEntry('Text', msg)
    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('Text')
    EndTextCommandDisplayHelp(2, false, false, -1)
end

Citizen.CreateThread(function ()
    while true do
        sleep = 1000
        local player = PlayerPedId()




        for k,v in pairs(KVL['Settings']['GiveBack']) do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - vector3(v.x, v.y, v.z))
            if dist < 10 then
                sleep = 3
                DrawMarker(39, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.75, 1.75, 1.75, 0, 255, 0, 100, false, true, 2, false, false, false, false)          
                if IsControlJustPressed(0, 38) then
                    if mulespawned then
                        if finished then
                            DeleteVehicle31()
                        end
                    elseif bensonspawned then
                        if finished then
                            DeleteVehicle31()
                        end
                    elseif pounderspawned then
                        if finished then
                            DeleteVehicle31()
                        end
                    end
                end
            end
        end

          Citizen.Wait(sleep)
      end
end)


function ShortRangeStart()
    local deliveryPoint = RandomShortDelivery()
    SellingBlip = SellingBlipOlustur(deliveryPoint)
    taken = true

    Citizen.CreateThread(function()
        while true do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - vector3(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z))

            local sleep = 2000
                if dist < 10 then
                    sleep = 3
                    if taken then

                        local player = PlayerPedId()
                        local vehicle = GetVehiclePedIsIn(player, false)
                        local driver = GetPedInVehicleSeat(vehicle, -1)
                        local incar = IsPedInAnyVehicle(player, false)
                        if incar then
                            sleep = 3
                            if player == driver then
                                DrawMarker(39, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.75, 1.75, 1.75, 0, 255, 0, 100, false, true, 2, false, false, false, false)     
                                if IsControlJustPressed(0, 38) then
                                    FinishShort()
                                end
                            end
                        end

                        
                    end
                end
            Citizen.Wait(sleep)
        end
    end)

end


function MediumRangeStart()
    local deliveryPoint = RandomMediumDelivery()
    SellingBlip = SellingBlipOlustur(deliveryPoint)
    taken = true

    Citizen.CreateThread(function()
        while true do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - vector3(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z))

            local sleep = 2000
                if dist < 10 then
                    sleep = 3
                    if taken then

                        local player = PlayerPedId()
                        local vehicle = GetVehiclePedIsIn(player, false)
                        local driver = GetPedInVehicleSeat(vehicle, -1)
                        local incar = IsPedInAnyVehicle(player, false)
                        if incar then
                            sleep = 3
                            if player == driver then
                                DrawMarker(39, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.75, 1.75, 1.75, 0, 255, 0, 100, false, true, 2, false, false, false, false)     
                                if IsControlJustPressed(0, 38) then
                                    FinishMedium()
                                end
                            end
                        end

                        
                    end
                end
            Citizen.Wait(sleep)
        end
    end)

end

function LongRangeStart()
    local deliveryPoint = RandomLongDelivery()
    SellingBlip = SellingBlipOlustur(deliveryPoint)
    taken = true

    Citizen.CreateThread(function()
        while true do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - vector3(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z))

            local sleep = 2000
                if dist < 10 then
                    sleep = 3
                    if taken then

                        local player = PlayerPedId()
                        local vehicle = GetVehiclePedIsIn(player, false)
                        local driver = GetPedInVehicleSeat(vehicle, -1)
                        local incar = IsPedInAnyVehicle(player, false)
                        if incar then
                            sleep = 3
                            if player == driver then
                                DrawMarker(39, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.75, 1.75, 1.75, 0, 255, 0, 100, false, true, 2, false, false, false, false)     
                                if IsControlJustPressed(0, 38) then
                                    FinishLong()
                                end
                            end
                        end

                        
                    end
                end
            Citizen.Wait(sleep)
        end
    end)

end



function FinishShort()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local driver = GetPedInVehicleSeat(vehicle, -1)
	local model = GetEntityModel(vehicle)
	local incar = IsPedInAnyVehicle(player, false)
	if incar then
		if player == driver then
            if taken then
			    if model == 1945374990 then
                    FreezeEntityPosition(vehicle, player, true)
                    ShowNotification(KVL['Locales']['StartingUnload'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent25'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent50'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent75'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent100'])
                    Citizen.Wait(1000)
                    ShowNotification(KVL['Locales']['DeliverySuccess'])

                    taken = false
                    RemoveBlip(SellingBlip)
                    finished = true
                    FreezeEntityPosition(vehicle, false)
                else
                    ShowNotification(KVL['Locales']['notjobcar'])
                end
            end
		else
            ShowNotification(KVL['Locales']['notdriver'])
		end
	else
        ShowNotification(KVL['Locales']['notinthecar'])
	end
end

function FinishMedium()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local driver = GetPedInVehicleSeat(vehicle, -1)
	local model = GetEntityModel(vehicle)
	local incar = IsPedInAnyVehicle(player, false)
	if incar then
		if player == driver then
            if taken then
                if model == 2053223216 then
                    FreezeEntityPosition(vehicle, player, true)

                    ShowNotification(KVL['Locales']['StartingUnload'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent25'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent50'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent75'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent100'])
                    Citizen.Wait(1000)
                    ShowNotification(KVL['Locales']['DeliverySuccess'])

                    taken = false
                    RemoveBlip(SellingBlip)
                    finished = true
                    FreezeEntityPosition(vehicle, false)
                else
                    ShowNotification(KVL['Locales']['notjobcar'])
                end
            end
		else
            ShowNotification(KVL['Locales']['notdriver'])
		end
	else
        ShowNotification(KVL['Locales']['notinthecar'])
	end
end

function FinishLong()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local driver = GetPedInVehicleSeat(vehicle, -1)
	local model = GetEntityModel(vehicle)
	local incar = IsPedInAnyVehicle(player, false)
	if incar then
		if player == driver then
            if taken then
			    if model == 2112052861 then
                    FreezeEntityPosition(vehicle, player, true)
                    ShowNotification(KVL['Locales']['StartingUnload'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent25'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent50'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent75'])
                    Citizen.Wait(KVL['Settings']['PercentWaitTime'])
                    ShowNotification(KVL['Locales']['Percent100'])
                    Citizen.Wait(1000)
                    ShowNotification(KVL['Locales']['DeliverySuccess'])

                    taken = false
                    RemoveBlip(SellingBlip)
                    finished = true
                    FreezeEntityPosition(vehicle, false)
                else
                    ShowNotification(KVL['Locales']['notjobcar'])
                end
            end
		else
            ShowNotification(KVL['Locales']['notdriver'])
		end
	else
        ShowNotification(KVL['Locales']['notinthecar'])
	end
end

function SellingBlipOlustur(x,y,z)
	local blip = AddBlipForCoord(x,y,z)
	SetBlipSprite(blip, 318)
	SetBlipColour(blip, 4)
    SetBlipAsShortRange(blip, true)
	AddTextEntry('MYBLIP', KVL['Locales']['deliverypoint'])
	BeginTextCommandSetBlipName('MYBLIP')
	AddTextComponentSubstringPlayerName(name)
	EndTextCommandSetBlipName(blip)
	return blip
end



function RandomShortDelivery()
    local randomIndex = math.random(1, #KVL['Settings']['DeliveryPoints']['ShortRange'])
    return KVL['Settings']['DeliveryPoints']['ShortRange'][randomIndex]
end

function RandomMediumDelivery()
    local randomIndex = math.random(1, #KVL['Settings']['DeliveryPoints']['MediumRange'])
    return KVL['Settings']['DeliveryPoints']['MediumRange'][randomIndex]
end

function RandomLongDelivery()
    local randomIndex = math.random(1, #KVL['Settings']['DeliveryPoints']['LongRange'])
    return KVL['Settings']['DeliveryPoints']['LongRange'][randomIndex]
end

mulespawned = false
function SpawnShortRangeCar()
	local player = PlayerPedId()
	local incar = IsPedInAnyVehicle(player, false)

    local vehicle = GetVehiclePedIsIn(player, false)
    local model = GetEntityModel(vehicle)


	if not incar then
		if not mulespawned then
            local randomSpawnPoint = GetRandomSpawnPoint()

			ESX.Game.SpawnVehicle('mule4', randomSpawnPoint, 285.63064575195, function(vehicle)
				local plate = 'KVL' .. math.random(100, 900)
				SetVehicleNumberPlateText(vehicle, plate)
				mulespawned = true
                ShortRangeStart()
				TaskWarpPedIntoVehicle(player, vehicle, -1)
                if KVL['Settings']['CustomCarKey'] then
                    GiveCarKey()
                end
			end)
			TriggerServerEvent('kvl-trucker:removemoney', KVL['Prices']['DepositPrice'])
		else
            ShowNotification(KVL['Locales']['alreadycar'])
		end
	end
end



function DeleteVehicle31()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)
    local driver = GetPedInVehicleSeat(vehicle, -1)
	local model = GetEntityModel(vehicle)
	local incar = IsPedInAnyVehicle(player, false)
	if incar then
			if player == driver then
            if mulespawned then
				if model == 1945374990 then
                    if finished then
            		    DeleteVehicle(vehicle)
                        if mulespawned then
            		        mulespawned = false
                            finished = false
                            TriggerServerEvent('kvl-truck:shortrangepayment')
                            TriggerServerEvent('kvl-trucker:addmoney', KVL['Prices']['DepositPrice'])
                        end
                    end
                end

            elseif pounderspawned then
                if model == 2112052861 then
                    if finished then
                        DeleteVehicle(vehicle)
                        if pounderspawned then
                            pounderspawned = false
                            finished = false
                            TriggerServerEvent('kvl-truck:mediumrangepayment')
                            TriggerServerEvent('kvl-trucker:addmoney', KVL['Prices']['DepositPrice'])
                        end
                    end
                end
                    
            elseif bensonspawned then
                if model == 2053223216 then
                    if finished then
                        DeleteVehicle(vehicle)
                        if bensonspawned then
                            bensonspawned = false
                            finished = false
                            TriggerServerEvent('kvl-truck:longrangepayment')
                            TriggerServerEvent('kvl-trucker:addmoney', KVL['Prices']['DepositPrice'])
                        end
                    end
                end
            end

    	else
            ShowNotification(KVL['Locales']['notrentjobcar'])
		end
	else
        ShowNotification(KVL['Locales']['notinthecar'])
	end
end




bensonspawned = false
function SpawnMediumRangeCar()
	local player = PlayerPedId()
	local incar = IsPedInAnyVehicle(player, false)

    local vehicle = GetVehiclePedIsIn(player, false)
    local model = GetEntityModel(vehicle)


	if not incar then
		if not bensonspawned then
            local randomSpawnPoint = GetRandomSpawnPoint()

			ESX.Game.SpawnVehicle('benson', randomSpawnPoint, 285.63064575195, function(vehicle)
				local plate = 'KVL' .. math.random(100, 900)
				SetVehicleNumberPlateText(vehicle, plate)
				bensonspawned = true
                MediumRangeStart()
				TaskWarpPedIntoVehicle(player, vehicle, -1)
                if KVL['Settings']['CustomCarKey'] then
                    GiveCarKey()
                end
			end)
			TriggerServerEvent('kvl-trucker:removemoney', KVL['Prices']['DepositPrice'])
		else
            ShowNotification(KVL['Locales']['alreadycar'])
		end
	end
end


RegisterNetEvent('kvl:notify', function(str)
    ShowNotification(str)
end)

pounderspawned = false
function SpawnLongRangeCar()
	local player = PlayerPedId()
	local incar = IsPedInAnyVehicle(player, false)

    local vehicle = GetVehiclePedIsIn(player, false)
    local model = GetEntityModel(vehicle)


	if not incar then
		if not pounderspawned then
            local randomSpawnPoint = GetRandomSpawnPoint()

			ESX.Game.SpawnVehicle('pounder', randomSpawnPoint, 285.63064575195, function(vehicle)
				local plate = 'KVL' .. math.random(100, 900)
				SetVehicleNumberPlateText(vehicle, plate)
				pounderspawned = true
                LongRangeStart()
				TaskWarpPedIntoVehicle(player, vehicle, -1)
                if KVL['Settings']['CustomCarKey'] then
                    GiveCarKey()
                end
			end)
			TriggerServerEvent('kvl-trucker:removemoney', KVL['Prices']['DepositPrice'])
		else
            ShowNotification(KVL['Locales']['alreadycar'])
		end
	end
end

function GetRandomSpawnPoint()
    local randomIndex = math.random(1, #KVL['Settings']['SpawnPoints'])
    return KVL['Settings']['SpawnPoints'][randomIndex]
end


if KVL['Settings']['Blip'] then
    local blcoords = vector3(KVL['Settings']['BlipCoords'].x, KVL['Settings']['BlipCoords'].y, KVL['Settings']['BlipCoords'].z)
    local blip = AddBlipForCoord(blcoords)
    SetBlipSprite(blip, KVL['Settings']['BlipSprite'])
    SetBlipScale(blip, KVL['Settings']['BlipScale'])
    SetBlipColour(blip, KVL['Settings']['BlipColour'])
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(KVL['Settings']['BlipName'])
    EndTextCommandSetBlipName(blip)
end

Citizen.CreateThread(function()
    for k,v in pairs(KVL['Peds']) do
        RequestModel(v.ped)
        while not HasModelLoaded(v.ped) do
            Wait(1)
        end
        stanley = CreatePed(1, v.ped, v.x, v.y, v.z - 1, v.h, false, true)
        SetBlockingOfNonTemporaryEvents(stanley, true)
        SetPedDiesWhenInjured(stanley, false)
        SetPedCanPlayAmbientAnims(stanley, true)
        SetPedCanRagdollFromPlayerImpact(stanley, false)
        SetEntityInvincible(stanley, true)
        FreezeEntityPosition(stanley, true)
        TaskStartScenarioInPlace(stanley, v.anim, 0, true);
        
    end
end)


RegisterCommand('truckmenufix', function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "close",})
end)


-- JOB & NUI Connections
RegisterNUICallback("ShortRangeStart", function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "close",})
    ESX.TriggerServerCallback('kvl-trucker:checkmoney', function(checkmoney)
        if checkmoney then
            SpawnShortRangeCar()
        else
            ShowNotification(KVL['Locales']['youneedmoney'])
        end
    end, KVL['Prices']['DepositPrice'])
end)

RegisterNUICallback("MediumRangeStart", function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "close",})
    ESX.TriggerServerCallback('kvl-trucker:checkmoney', function(checkmoney)
        if checkmoney then
            SpawnMediumRangeCar()
        else
            ShowNotification(KVL['Locales']['youneedmoney'])
        end
    end, KVL['Prices']['DepositPrice'])
end)

RegisterNUICallback("LongRangeStart", function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "close",})
    ESX.TriggerServerCallback('kvl-trucker:checkmoney', function(checkmoney)
        if checkmoney then
            SpawnLongRangeCar()
        else
            ShowNotification(KVL['Locales']['youneedmoney'])
        end
    end, KVL['Prices']['DepositPrice'])
end)

RegisterNUICallback("ShowXpTable", function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "close",})
    ExecuteCommand('xp')
end)


--

RegisterNUICallback("exit", function ()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close",
    })
end)
