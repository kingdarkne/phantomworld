local policeAlerts = {}

CreateThread(function()
	local currentTime = os.time()
	while true do
		currentTime = os.time()
		local bodyguards = MySQL.query.await("SELECT * FROM electus_bodyguards")
		
		for k, bodyguard in pairs(bodyguards) do
			local timeDiff = currentTime - bodyguard.time
			local daysPassed = timeDiff / 86400
			
			if daysPassed >= bodyguard.days then
				MySQL.update.await("DELETE FROM electus_bodyguards WHERE `slot`=? AND `identifier`=?", {
					bodyguard.slot,
					bodyguard.identifier
				})
				
				for _, playerId in ipairs(GetPlayers()) do
					local player = GetPlayer(playerId)
					local identifier = GetPlayerIdentifier(player)
					if identifier == bodyguard.identifier then
						TriggerClientEvent("electus_bodyguards:deleteBodyguard", playerId, bodyguard.slot)
						break
					end
				end
			end
		end
		
		Wait(300000)
	end
end)

lib.callback.register("electus_bodyguards:removeWeapon", function(src, bodyguard)
	local player = GetPlayer(src)
	local identifier = GetPlayerIdentifier(player)
	AddInventoryItem(src, bodyguard.weapon, 1)
	MySQL.update.await("UPDATE electus_bodyguards SET `weapon` = NULL WHERE `identifier`=? AND `slot`=?", {
		identifier,
		bodyguard.slot
	})
	return true
end)

lib.callback.register("electus_bodyguards:giveWeapon", function(src, bodyguard, weapon)
	local player = GetPlayer(src)
	local identifier = GetPlayerIdentifier(player)
	local hasWeapon = GetInventoryCount(src, weapon) > 0
	
	if not hasWeapon then
		Notify(src, L("noWeapon"), "error")
	end
	
	RemoveInventoryItem(src, weapon, 1)
	MySQL.insert.await("UPDATE electus_bodyguards SET `weapon` = @weapon WHERE `identifier`=@identifier AND `slot`=@slot", {
		["@identifier"] = identifier,
		["@slot"] = bodyguard.slot,
		["@weapon"] = weapon
	})
	return true
end)

lib.callback.register("electus_bodyguards:updateBodyguard", function(src, bodyguard)
	UpdateBodyguardToDB(src, bodyguard)
	return true
end)

lib.callback.register("electus_bodyguards:syncAmmo", function(src, bodyguard)
	local player = GetPlayer(src)
	local identifier = GetPlayerIdentifier(player)
	local ammoCount = GetInventoryCount(src, Config.weaponConfiguration[bodyguard.weapon].ammoName)
	
	MySQL.update.await("UPDATE electus_bodyguards SET `ammo` = @ammo WHERE `identifier`=@identifier AND `slot`=@slot", {
		["@identifier"] = identifier,
		["@slot"] = bodyguard.slot,
		["@ammo"] = ammoCount
	})
	return true
end)

lib.callback.register("electus_bodyguards:removeAmmo", function(src, bodyguard, ammoAmount)
	local player = GetPlayer(src)
	local identifier = GetPlayerIdentifier(player)
	local ammoName = Config.weaponConfiguration[bodyguard.weapon].ammoName
	AddInventoryItem(src, ammoName, ammoAmount)
	MySQL.update.await("UPDATE electus_bodyguards SET `ammo` = 0 WHERE `identifier`=@identifier AND `slot`=@slot", {
		["@identifier"] = identifier,
		["@slot"] = bodyguard.slot
	})
	return true
end)

lib.callback.register("electus_bodyguards:giveAmmo", function(src, bodyguard, ammoName, amount)
	local player = GetPlayer(src)
	local identifier = GetPlayerIdentifier(player)
	local hasEnough = amount <= GetInventoryCount(src, ammoName)
	
	if not hasEnough then
		Notify(src, L("noAmmo"), "error")
		return false
	end
	
	RemoveInventoryItem(src, ammoName, amount)
	MySQL.update.await("UPDATE electus_bodyguards SET `ammo` =  `ammo`+@ammo WHERE `identifier`=@identifier AND `slot`=@slot", {
		["@identifier"] = identifier,
		["@slot"] = bodyguard.slot,
		["@ammo"] = amount
	})
	return true
end)

lib.callback.register("electus_bodyguards:createBodyguard", function(src, model, coords)
	if not coords then
		local playerPed = GetPlayerPed(src)
		coords = GetEntityCoords(playerPed)
	end
	
	local playerPed = GetPlayerPed(src)
	local ped = CreatePed(4, GetHashKey(model), coords, GetEntityHeading(playerPed), true, false)
	local startTime = GetGameTimer()
	
	while not DoesEntityExist(ped) do
		Wait(100)
		local elapsed = GetGameTimer() - startTime
		if elapsed > 10000 then
			return nil
		end
	end
	
	SetPedRandomComponentVariation(ped, 0)
	local netId = NetworkGetNetworkIdFromEntity(ped)
	SetEntityIgnoreRequestControlFilter(ped, true)
	return netId
end)

lib.callback.register("electus_bodyguards:spawnBackup", function(src, backupData, spawnCoords)
	local player = GetPlayer(src)
	local vehicles = {}
	local vehicleModel = backupData.vehicle
	
	for i = 1, #spawnCoords do
		local vehicle = CreateVehicleServerSetter(
			GetHashKey(vehicleModel),
			"automobile",
			spawnCoords[i].xyz,
			spawnCoords[i].w
		)
		local startTime = GetGameTimer()
		
		while not DoesEntityExist(vehicle) do
			Wait(100)
			local elapsed = GetGameTimer() - startTime
			if elapsed > 10000 then
				print("timed out")
				break
			end
		end
		
		local netId = NetworkGetNetworkIdFromEntity(vehicle)
		SetEntityIgnoreRequestControlFilter(vehicle, true)
		vehicles[#vehicles + 1] = netId
	end
	
	local peds = {}
	for i = 1, #backupData.peds do
		local pedData = backupData.peds[i]
		local vehicleIndex = math.floor((i - 1) / 2) + 1
		local vehicle = NetworkGetEntityFromNetworkId(vehicles[vehicleIndex])
		local pedCoords = GetEntityCoords(vehicle)
		
		local ped = CreatePed(4, GetHashKey(pedData.model), pedCoords, true, false)
		local startTime = GetGameTimer()
		
		while not DoesEntityExist(ped) do
			Wait(100)
			local elapsed = GetGameTimer() - startTime
			if elapsed > 10000 then
				print("timed out")
				break
			end
		end
		
		while GetVehiclePedIsIn(ped, false) == 0 do
			local seatIndex = -1 * (i % 2)
			SetPedIntoVehicle(ped, vehicle, seatIndex)
			Wait(500)
		end
		
		SetPedRandomComponentVariation(ped, 0)
		local netId = NetworkGetNetworkIdFromEntity(ped)
		SetEntityIgnoreRequestControlFilter(ped, true)
		peds[#peds + 1] = netId
	end
	
	return peds, vehicles
end)

lib.callback.register("electus_bodyguards:recruit", function(src, recruitData)
	local player = GetPlayer(src)
	local identifier = GetPlayerIdentifier(player)
	local existingBodyguards = MySQL.query.await("SELECT * FROM electus_bodyguards WHERE identifier = ?", {identifier})
	local cash = GetCashMoney(player)
	
	if cash < recruitData.price then
		Notify(src, L("notEnoughMoney"), "error")
		return false
	end
	
	if #existingBodyguards >= Config.maxSlots then
		Notify(src, L("maxSlots"), "error")
		return false
	end
	
	local slot = -1
	for i = 1, Config.maxSlots do
		local found = false
		for j = 1, #existingBodyguards do
			if existingBodyguards[j].slot == i then
				found = true
				break
			end
		end
		if not found then
			slot = i
			break
		end
	end
	
	if slot == -1 then
		Notify(src, L("maxSlots"), "error")
		return false
	end
	
	if recruitData.price < Config.recruit.recruitPriceRange.min or
		recruitData.days < Config.recruit.recruitDaysRange.min or
		recruitData.price > Config.recruit.recruitPriceRange.max or
		recruitData.days > Config.recruit.recruitDaysRange.max then
		Notify(src, L("invalidPriceOrDays"), "error")
		return false
	end
	
	RemoveCashMoney(player, recruitData.price)
	
	MySQL.insert.await([[
		INSERT INTO electus_bodyguards (`identifier`, `slot`, `model`, `weapon`, `ammo`, `time`, `days`, `isDead`, `inService`, `isRecruit`, `isBackup`, `components`) 
		VALUES (@identifier, @slot, @model, @weapon, @ammo, @time, @days, @isDead, @inService, @isRecruit, @isBackup, @components)
	]], {
		["@identifier"] = identifier,
		["@slot"] = slot,
		["@model"] = recruitData.model,
		["@weapon"] = recruitData.weapon,
		["@ammo"] = recruitData.ammo,
		["@time"] = os.time(),
		["@days"] = recruitData.days,
		["@isDead"] = 0,
		["@inService"] = 1,
		["@isRecruit"] = 1,
		["@isBackup"] = 0,
		["@components"] = json.encode(recruitData.components)
	})
	
	return {
		slot = slot,
		model = recruitData.model,
		weapon = recruitData.weapon,
		ammo = recruitData.ammo,
		time = os.time(),
		days = recruitData.days,
		isDead = 0,
		inService = 1,
		isRecruit = 1,
		isBackup = 0,
		components = recruitData.components
	}
end)

function AlertPolice(id, coords)
	local alertIndex = #policeAlerts + 1
	policeAlerts[alertIndex] = {
		id = id,
		coords = coords
	}
	
	local dispatchState = GetResourceState("qs-dispatch")
	if dispatchState == "started" then
		TriggerEvent("qs-dispatch:server:CreateDispatchCall", {
			job = Config.policeJobs,
			callLocation = coords,
			callCode = {
				code = L("dispatch_label"),
				snippet = L("dispatch_brevity_code")
			},
			message = L("recruitment_dispatch"),
			flashes = true,
			image = nil,
			blip = {
				sprite = 108,
				scale = 1.5,
				colour = 1,
				flashes = true,
				text = L("dispatch_label"),
				time = 300000
			}
		})
	else
		dispatchState = GetResourceState("ps-dispatch")
		if dispatchState == "started" then
			TriggerEvent("ps-dispatch:server:notify", {
				message = L("recruitment_dispatch"),
				codeName = L("dispatch_label"),
				code = L("dispatch_brevity_code"),
				icon = "fas fa-person-rifle",
				priority = 1,
				coords = coords,
				jobs = Config.policeJobs,
				blipSprite = 108,
				blipColour = 32,
				blipScale = 1.5,
				blipLength = 3
			})
		else
			dispatchState = GetResourceState("cd_dispatch")
			if dispatchState == "started" then
				TriggerClientEvent("cd_dispatch:AddNotification", -1, {
					job_table = Config.policeJobs,
					coords = coords,
					title = L("dispatch_label"),
					message = L("recruitment_dispatch"),
					flash = 0,
					unique_id = tostring(math.random(0, 9999999)),
					sound = 1,
					blip = {
						sprite = 108,
						scale = 1.5,
						colour = 1,
						flashes = false,
						text = L("dispatch_label"),
						time = 5,
						radius = 0
					}
				})
			else
				TriggerClientEvent("electus_bodyguards:alertPolice", -1, id, coords)
			end
		end
	end
end

RegisterNetEvent("electus_bodyguards:removePoliceAlert", function(id)
	for i = 1, #policeAlerts do
		if policeAlerts[i].id == id then
			table.remove(policeAlerts, i)
			break
		end
	end
	TriggerClientEvent("electus_bodyguards:removePoliceAlert", -1, id)
end)

RegisterNetEvent("electus_bodyguards:getPoliceAlerts", function()
	local src = source
	for i = 1, #policeAlerts do
		TriggerClientEvent("electus_bodyguards:alertPolice", src, policeAlerts[i].coords)
	end
end)

RegisterNetEvent("electus_bodyguards:callCops", function(id, coords)
	AlertPolice(id, coords)
end)
