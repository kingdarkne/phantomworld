local guardPeds = {}

RegisterNetEvent("electus_bodyguards:spawnedGuardPed", function(data)
	local netId = data.netId
	while NetworkGetEntityFromNetworkId(netId) == 0 do
		Wait(1)
	end
	
	NetworkRequestControlOfNetworkId(netId)
	while not NetworkHasControlOfNetworkId(netId) do
		Wait(1)
	end
	
	TaskWanderInArea(data.ped, data.coords, data.radius, 10, 2.0)
	SetPedKeepTask(data.ped, true)
end)

function StopGuarding(bodyguard)
	while not NetworkHasControlOfNetworkId(bodyguard.netId) do
		NetworkRequestControlOfNetworkId(bodyguard.netId)
		Wait(500)
	end
	
	lib.callback.await("electus_bodyguards:disableBoyguardGuard", false, bodyguard)
	local ped = NetworkGetEntityFromNetworkId(bodyguard.netId)
	bodyguard.ped = ped
	bodyguard.task = nil
end

function StartGuard(bodyguard)
	lib.showTextUI(L("pressToGuard", {
		key = Config.keyActions.guard,
		increase = Config.keyActions.guardAreaIncrease,
		decrease = Config.keyActions.guardAreaDecrease,
		key2 = Config.keyActions.guardCancel
	}))
	
	CreateThread(function()
		local radius = Config.guarding.minRadius
		while true do
			local coords = GetWorldCoordsFromScreen()
			DrawMarker(
				1,
				coords.x, coords.y, coords.z,
				0, 0, 0,
				0, 0, 0,
				radius, radius, 1.0,
				255, 0, 0, 255,
				false, false, 2,
				false, false, false, false
			)
			Wait(1)
			
			if IsControlJustPressed(0, Keys[Config.keyActions.guard].key) then
				bodyguard.coords = coords
				bodyguard.radius = radius
				break
			end
			
			if IsControlJustPressed(0, Keys[Config.keyActions.guardAreaIncrease].key) then
				if radius < Config.guarding.maxRadius then
					radius = radius + 1.0
				end
			end
			
			if IsControlJustPressed(0, Keys[Config.keyActions.guardAreaDecrease].key) then
				if radius > Config.guarding.minRadius then
					radius = radius - 1.0
				end
			end
			
			if IsControlJustPressed(0, Keys[Config.keyActions.guardCancel].key) then
				lib.hideTextUI()
				return
			end
		end
		
		lib.hideTextUI()
		local netId = NetworkGetNetworkIdFromEntity(bodyguard.ped)
		bodyguard.netId = netId
		bodyguard.task = "guarding"
		TriggerServerEvent("electus_bodyguards:setBodyguardToGuard", bodyguard)
		TaskWanderInArea(bodyguard.ped, bodyguard.coords, bodyguard.radius, 2, 2.0)
		SetPedKeepTask(bodyguard.ped, true)
	end)
end

RegisterNetEvent("electus_bodyguards:stopAttack", function(data)
	local ped = NetworkGetEntityFromNetworkId(data.netId)
	while not NetworkHasControlOfEntity(ped) do
		NetworkRequestControlOfEntity(ped)
		Wait(500)
	end
	
	if DoesEntityExist(ped) then
		SetCurrentPedWeapon(ped, 2725352035, true)
		TaskWanderInArea(ped, data.coords, data.radius, 10, 2.0)
		SetPedKeepTask(ped, true)
		TriggerServerEvent("electus_bodyguards:finishAttacking", data)
	end
end)

RegisterNetEvent("electus_bodyguards:attackNetId", function(bodyguard, targetNetId)
	local targetPed = NetworkGetEntityFromNetworkId(targetNetId)
	local bodyguardPed = NetworkGetEntityFromNetworkId(bodyguard.netId)
	
	while not NetworkHasControlOfEntity(bodyguardPed) do
		NetworkRequestControlOfEntity(bodyguardPed)
		Wait(500)
	end
	
	if DoesEntityExist(targetPed) then
		TaskCombatPed(bodyguardPed, targetPed, 0, 16)
		SetPedKeepTask(bodyguardPed, true)
		
		CreateThread(function()
			while DoesEntityExist(targetPed) and DoesEntityExist(bodyguardPed) do
				local bodyguardCoords = GetEntityCoords(bodyguardPed)
				local distance = #(bodyguardCoords - bodyguard.coords)
				if distance >= bodyguard.radius * 2.0 then
					break
				end
				Wait(1000)
			end
			
			if DoesEntityExist(bodyguardPed) then
				TriggerServerEvent("electus_bodyguards:stopAttack", bodyguard)
			end
		end)
	end
end)

RegisterNetEvent("electus_bodyguards:updateGuardPeds", function(guards)
	guardPeds = guards
end)

CreateThread(function()
	while true do
		Wait(2000)
		for k, guard in pairs(guardPeds) do
			local guardCoords = guard.coords
			local playerCoords = GetEntityCoords(PlayerPedId())
			local distance = #(playerCoords - guardCoords)
			
			if distance < guard.radius then
				local netId = guard.netId
				local ped = NetworkGetEntityFromNetworkId(netId)
				if ped == 0 then
					lib.callback.await("electus_bodyguards:spawnGuardPeds", false, netId)
				else
					TriggerServerEvent("electus_bodyguards:attackNetId", guard, NetworkGetNetworkIdFromEntity(PlayerPedId()))
				end
			end
		end
	end
end)
