local isBackupBeingCalled = false

RegisterCommand("backup", function()
	if GetJob() == "police" then
		local options = {}
		local policeOption = {}
		policeOption.label = L("police")
		policeOption.args = { value = "police" }
		
		local swatOption = {}
		swatOption.label = L("swat")
		swatOption.args = { value = "swat" }
		
		local highwaypatrolOption = {}
		highwaypatrolOption.label = L("highwaypatrol")
		highwaypatrolOption.args = { value = "highwaypatrol" }
		
		local sheriffOption = {}
		sheriffOption.label = L("sheriff")
		sheriffOption.args = { value = "sheriff" }
		
		options[1] = policeOption
		options[2] = swatOption
		options[3] = highwaypatrolOption
		options[4] = sheriffOption
		
		local hasBackup = false
		for k, v in pairs(Bodyguards) do
			if v.isBackup then
				hasBackup = true
				break
			end
		end
		
		if hasBackup then
			local terminateOption = {}
			terminateOption.label = L("terminateBackup")
			terminateOption.args = { value = "terminateBackup" }
			table.insert(options, terminateOption)
		end
		
		lib.registerMenu({
			id = "backup_menu",
			title = L("backupMenu"),
			position = "top-right",
			options = options,
		}, function(selected, scrollIndex, args)
			local val = args.value
			if val == "terminateBackup" then
				RemoveAllBackup()
				Notify(L("backupTerminated"), "success")
			elseif val then
				CallBackup(val)
			end
		end)
		
		lib.showMenu("backup_menu")
	end
end, false)

function RemoveAllBackup()
	for k, bodyguard in pairs(Bodyguards) do
		if bodyguard.isBackup then
			if bodyguard.inService and not bodyguard.isDead then
				local health = GetEntityHealth(bodyguard.ped)
				if health > 0.0 then
					if bodyguard.vehicle then
						if DoesEntityExist(bodyguard.vehicle) then
							local pedCoords = GetEntityCoords(bodyguard.ped)
							local vehCoords = GetEntityCoords(bodyguard.vehicle)
							local distance = #(pedCoords - vehCoords)
							if distance < 100.0 then
								CreateThread(function()
									TaskEnterVehicle(bodyguard.ped, bodyguard.vehicle, -1, -1, 2.0, 1, 0)
									lib.waitFor(function()
										return GetVehiclePedIsIn(bodyguard.ped, false) == bodyguard.vehicle
									end, L("pedCouldntEnterVehicle"), 100000)
									
									if GetVehiclePedIsIn(bodyguard.ped, false) == bodyguard.vehicle then
										TaskVehicleDriveWander(bodyguard.ped, bodyguard.vehicle, 20.0, 786469)
										Wait(5000)
										DeleteEntity(bodyguard.ped)
										DeleteEntity(bodyguard.vehicle)
										TriggerServerEvent("electus_bodyguards:terminateContract", bodyguard.slot)
									else
										DeleteEntity(bodyguard.ped)
										TriggerServerEvent("electus_bodyguards:terminateContract", bodyguard.slot)
									end
									Bodyguards[k] = nil
								end)
							end
						end
					end
				end
			end
			
			if bodyguard.isBackup then
				TriggerServerEvent("electus_bodyguards:terminateContract", bodyguard.slot)
				Bodyguards[k] = nil
			end
		end
	end
end

function GetVehicleNodeHeading(coords)
	local density, flags, heading = GetVehicleNodeProperties(coords.x, coords.y, coords.z)
	return heading
end

function GetRandomRoadCoords(coords)
	local distance = 0
	local roadCoords = vector3(0, 0, 0)
	local nodeIndex = math.random(10, 20)
	local heading = 0
	local nodeFlags = 66
	
	while distance < 100.0 or nodeFlags == 66 or nodeFlags == 64 do
		nodeIndex = nodeIndex + math.random(10, 20)
		local success, outCoords, outHeading = GetNthClosestVehicleNodeFavourDirection(
			coords.x, coords.y, coords.z,
			coords.x, coords.y, coords.z,
			nodeIndex, 0, 4194304, 0
		)
		heading = outHeading
		roadCoords = outCoords
		local ret = success
		local density, flags = GetVehicleNodeProperties(roadCoords.x, roadCoords.y, roadCoords.z)
		nodeFlags = flags
		distance = #(coords - roadCoords)
		if distance >= 200.0 then
			break
		end
		Wait(1)
	end
	
	return vector4(roadCoords.x, roadCoords.y, roadCoords.z, heading)
end

function CallBackup(backupType)
	if isBackupBeingCalled then
		Notify(L("backupIsBeingCalled"), "error")
		return
	end
	
	isBackupBeingCalled = true
	local backupConfig = Config.backups[backupType]
	local vehicleModel = backupConfig.vehicle
	
	lib.requestModel(vehicleModel)
	
	for i = 1, #backupConfig.peds do
		lib.requestModel(backupConfig.peds[i].model)
	end
	
	local emptySlots = lib.callback.await("electus_bodyguards:getNbrOfEmptyBackupSlots", false)
	local backupData = {}
	
	if not emptySlots or emptySlots == 0 then
		isBackupBeingCalled = false
		Notify(L("yourBackupIsFull"), "error")
		return false
	else
		backupData.peds = {}
		for i = 1, emptySlots do
			backupData.peds[i] = backupConfig.peds[i]
			backupData.vehicle = backupConfig.vehicle
		end
	end
	
	if emptySlots < #backupConfig.peds then
		Notify(L("backupLimitReached"), "error")
	end
	
	Notify(L("backupCalled"), "success")
	local playerCoords = GetEntityCoords(PlayerPedId())
	local numVehicles = math.ceil(#backupData.peds / 2)
	local spawnCoords = {}
	
	for i = 1, numVehicles do
		spawnCoords[i] = GetRandomRoadCoords(playerCoords)
	end
	
	local pedNetIds, vehicleNetIds = lib.callback.await("electus_bodyguards:spawnBackup", false, backupData, spawnCoords)
	
	for i = 1, #vehicleNetIds do
		local vehicleNetId = vehicleNetIds[i]
		while not NetworkDoesNetworkIdExist(vehicleNetId) do
			Wait(0)
		end
		
		while not NetworkHasControlOfNetworkId(vehicleNetId) do
			NetworkRequestControlOfNetworkId(vehicleNetId)
			Wait(500)
		end
		
		lib.callback.await("electus_bodyguards:disableControlFilter", false, vehicleNetId)
		local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
		vehicleNetIds[i] = vehicle
		
		SetVehicleOnGroundProperly(vehicle)
		SetVehicleEngineOn(vehicle, true, true, true)
		SetVehicleSiren(vehicle, true)
		SetVehicleLights(vehicle, 2)
		SetVehicleNumberPlateText(vehicle, "POLICE")
		SetVehicleEngineHealth(vehicle, 1000.0)
		SetVehicleFixed(vehicle)
		SetVehicleDirtLevel(vehicle, 0.0)
	end
	
	for i = 1, #pedNetIds do
		local pedNetId = pedNetIds[i]
		local bodyguardData = {}
		
		while not NetworkDoesNetworkIdExist(pedNetId) do
			Wait(0)
		end
		
		NetworkRequestControlOfNetworkId(pedNetId)
		while not NetworkHasControlOfNetworkId(pedNetId) do
			Wait(0)
		end
		
		lib.callback.await("electus_bodyguards:disableControlFilter", false, pedNetId)
		local ped = NetworkGetEntityFromNetworkId(pedNetId)
		bodyguardData.ped = ped
		bodyguardData.inService = true
		bodyguardData.isDead = false
		bodyguardData.isBackup = true
		bodyguardData.days = 1
		bodyguardData.time = 0
		bodyguardData.model = backupData.peds[i].model
		bodyguardData.weapon = backupData.peds[i].weapon
		bodyguardData.ammo = backupData.peds[i].ammo
		
		local vehicleIndex = math.floor((i - 1) / 2) + 1
		local vehicle = vehicleNetIds[vehicleIndex]
		bodyguardData.vehicle = vehicle
		
		local bodyguard = SetBodyguardAttributes(bodyguardData)
		
		if i % 2 == 1 then
			TaskVehicleDriveToCoordLongrange(bodyguard.ped, vehicle, playerCoords.x, playerCoords.y, playerCoords.z, 20.0, 786469, 15.0)
			SetPedKeepTask(bodyguard.ped, true)
			SetDriverAbility(bodyguard.ped, 1.0)
			
			CreateThread(function()
				while GetScriptTaskStatus(bodyguard.ped, 567490903) ~= 7 do
					Wait(250)
				end
				TaskLeaveAnyVehicle(bodyguard.ped, 0, 0)
				Bodyguards[bodyguard.slot].task = nil
			end)
		else
			CreateThread(function()
				local vehicleIndex = math.floor((i - 1) / 2) + 1
				local vehicle = vehicleNetIds[vehicleIndex]
				
				while GetEntitySpeed(vehicle) > 0.5 or #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId())) > 15.0 do
					Wait(500)
				end
				TaskLeaveAnyVehicle(bodyguard.ped, 0, 0)
				Bodyguards[bodyguard.slot].task = nil
			end)
		end
	end
	
	isBackupBeingCalled = false
end

function SetBodyguardAttributes(bodyguard)
	local model = bodyguard.model
	local modelIndex, type = GetModelIndex(model)
	local shooting = 0
	local driving = 0
	local armor = 0
	
	if not modelIndex or not type then
		shooting = Config.backupStats.shooting
		driving = Config.backupStats.driving
		armor = Config.backupStats.armor
	else
		shooting = Config.shop[type][modelIndex].shooting
		driving = Config.shop[type][modelIndex].driving
		armor = Config.shop[type][modelIndex].armor
	end
	
	local ped = bodyguard.ped
	
	if bodyguard.weapon then
		local weaponHash = GetHashKey(bodyguard.weapon)
		GiveWeaponToPed(ped, weaponHash, bodyguard.ammo, true, false)
		SetCurrentPedWeapon(ped, weaponHash, true)
	end
	
	SetEntityAsMissionEntity(ped, true, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	SetPedFleeAttributes(ped, 0, false)
	SetPedAccuracy(ped, shooting * 2 * 10)
	SetDriverAbility(ped, driving * 0.3)
	SetPedArmour(ped, armor * 33)
	SetPedDropsWeaponsWhenDead(ped, false)
	SetEntityHealth(ped, 200.0)
	SetPedRelationshipGroupHash(ped, RelationHash)
	SetCurrentPedWeapon(ped, 2725352035, true)
	
	local slot = lib.callback.await("electus_bodyguards:getNextBackupSlot", false)
	
	if slot then
		local components = GetPedComponents(ped)
		Bodyguards[slot] = {
			ped = ped,
			slot = slot,
			model = model,
			weapon = bodyguard.weapon,
			ammo = bodyguard.ammo,
			time = bodyguard.time,
			days = bodyguard.days,
			isDead = bodyguard.isDead,
			inService = bodyguard.inService,
			isTemp = bodyguard.isTemp,
			originalVehicle = bodyguard.originalVehicle,
			isBackup = true,
			task = "backupDriving",
			vehicle = bodyguard.vehicle,
			components = components,
		}
		
		TriggerServerEvent("electus_bodyguards:insertBackupBodyguard", slot, model, bodyguard.weapon, bodyguard.days, components)
		
		if Config.targetSystem ~= "none" then
			exports["qtarget"]:AddTargetEntity(Bodyguards[slot].ped, {
				options = {
					{
						label = L("interact"),
						action = function()
							InteractBodyguard(Bodyguards[slot])
						end,
					},
				},
				distance = 2,
			})
		end
		
		return Bodyguards[slot]
	end
end
