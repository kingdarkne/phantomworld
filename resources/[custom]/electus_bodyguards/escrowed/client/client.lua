local seat1 = {}
seat1.index = -1
seat1.id = -1

local seat2 = {}
seat2.index = 0
seat2.id = -1

local seat3 = {}
seat3.index = 1
seat3.id = -1

local seat4 = {}
seat4.index = 2
seat4.id = -1

Seats = {seat1, seat2, seat3, seat4}

local isInVehicle = false
local isAiming = false
local hasShot = false

function GetNumBodyguards()
	local count = 0
	for k in pairs(Bodyguards) do
		count = count + 1
	end
	return count
end

function GetFirstBodyguardIndex()
	local index = nil
	for k, bodyguard in pairs(Bodyguards) do
		if bodyguard.inService == 1 and bodyguard.isDead == 0 then
			index = k
			break
		end
	end
	return index
end

function GetPedFromSeat(seatIndex)
	for k, seat in pairs(Seats) do
		if seat.index == seatIndex then
			return seat.id
		end
	end
end

function SwitchStayPut(bodyguard)
	if bodyguard.task == nil then
		bodyguard.task = "stayPut"
		ClearPedTasks(bodyguard.ped)
	else
		bodyguard.task = nil
	end
end

function HandleEnteredVehicle(slot, vehicle, seatIndex)
	local bodyguard = Bodyguards[slot]
	local isInVeh = IsPedInAnyVehicle(bodyguard.ped, false)
	
	while not isInVeh do
		if bodyguard.task ~= "vehicle" then
			break
		end
		Wait(250)
		isInVeh = IsPedInAnyVehicle(bodyguard.ped, false)
		local seatFree = IsVehicleSeatFree(vehicle, seatIndex)
		if not seatFree and not isInVeh then
			bodyguard.task = nil
			isInVehicle = false
			break
		end
	end
	
	bodyguard.isInVehicle = true
	bodyguard.task = nil
	SendReactMessage("vehicleUpdated", Seats)
end

function GetOffsetPosition(slot)
	local offsets = {
		{-1.0, 0.0},
		{1.0, 0.0},
		{-1.0, 1.0},
		{1.0, 1.0},
		{-1.0, -1.0},
		{1.0, -1.0},
		{0.0, 1.0},
		{0.0, -1.0},
	}
	
	local index = slot % 8
	if index == 0 then
		return offsets[8]
	else
		return offsets[index]
	end
end

CreateThread(function()
	while true do
		Wait(2000)
		local numBodyguards = GetNumBodyguards()
		if numBodyguards > 0 then
			local firstIndex = GetFirstBodyguardIndex()
			if firstIndex then
				local playerPed = PlayerPedId()
				local targetEntity, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(), -1)
				local vehicle = GetVehiclePedIsIn(playerPed, false)
				local isParking = GetIsTaskActive(Bodyguards[firstIndex].ped, 259)
				if not isParking then
					isParking = false
				end
				local hasTask = Bodyguards[firstIndex].task
				if not hasTask then
					hasTask = nil
				end
				
				if not hasTask and not isParking then
					for k, bodyguard in pairs(Bodyguards) do
						if bodyguard.inService then
							if not bodyguard.isInVehicle then
								if not bodyguard.task then
									local offset = GetOffsetPosition(bodyguard.slot)
									TaskFollowToOffsetOfEntity(
										bodyguard.ped,
										playerPed,
										offset[1],
										offset[2],
										0.0,
										GetEntitySpeed(PlayerPedId()) + 2.0,
										-1,
										2.0,
										1
									)
								end
							end
						end
					end
				end
				
				if vehicle ~= 0 then
					if not isInVehicle then
						SendReactMessage("numberOfSeats", GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)))
						SendReactMessage("setMaxSpeed", GetVehicleEstimatedMaxSpeed(vehicle))
						local playerCoords = GetEntityCoords(PlayerPedId())
						
						for k, bodyguard in pairs(Bodyguards) do
							local bodyguardCoords = GetEntityCoords(bodyguard.ped)
							local distance = #(playerCoords - bodyguardCoords)
							if distance < 15.0 then
								for i = 1, #Seats do
									if Seats[i].id == -1 then
										local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
										if i <= maxSeats then
											local seatFree = IsVehicleSeatFree(vehicle, Seats[i].index)
											if seatFree then
												bodyguard.task = "vehicle"
												ClearPedTasksImmediately(bodyguard.ped)
												TaskEnterVehicle(bodyguard.ped, vehicle, -1, Seats[i].index, 2.0, 1, 0)
												SetPedKeepTask(bodyguard.ped, true)
												Seats[i].id = bodyguard.slot
												if Seats[i].index == -1 then
													VehOptions.driver = k
												end
												CreateThread(function()
													HandleEnteredVehicle(k, vehicle, Seats[i].index)
												end)
												break
											end
										end
									end
								end
							end
						end
						isInVehicle = true
					end
				else
					if vehicle == 0 then
						if isInVehicle then
							isInVehicle = false
							for k, bodyguard in pairs(Bodyguards) do
								TaskLeaveVehicle(bodyguard.ped, GetVehiclePedIsIn(PlayerPedId(), true), 1)
								bodyguard.task = nil
								bodyguard.isInVehicle = nil
							end
							for k, seat in pairs(Seats) do
								seat.id = -1
							end
							SendReactMessage("vehicleUpdated", Seats)
						end
					elseif vehicle ~= 0 then
						local needsUpdate = false
						for i = 1, #Seats do
							local pedInSeat = GetPedInVehicleSeat(vehicle, Seats[i].index)
							local found = false
							for k, bodyguard in pairs(Bodyguards) do
								if bodyguard.ped == pedInSeat then
									if bodyguard.slot == Seats[i].id then
										found = true
										break
									else
										Seats[i].id = bodyguard.slot
										found = true
										needsUpdate = true
										break
									end
								end
							end
							if not found then
								if Seats[i].id ~= -1 then
									Seats[i].id = -1
									needsUpdate = true
								end
							end
						end
						if needsUpdate then
							SendReactMessage("vehicleUpdated", Seats)
						end
					end
				end
				
				if targetEntity then
					if not isAiming then
						local isBodyguard = false
						for k, bodyguard in pairs(Bodyguards) do
							if bodyguard.ped == targetPed then
								isBodyguard = true
								break
							end
						end
						for k, bodyguard in pairs(Bodyguards) do
							if not isBodyguard then
								if IsEntityAPed(targetPed) then
									isAiming = true
									hasShot = false
									bodyguard.task = "aiming"
									ClearPedTasks(bodyguard.ped)
									SetCurrentPedWeapon(bodyguard.ped, GetHashKey(bodyguard.weapon), true)
									TaskAimGunAtEntity(bodyguard.ped, targetPed, -1)
									SetPedKeepTask(bodyguard.ped, true)
								end
							end
						end
					end
				elseif not targetEntity then
					if isAiming then
						isAiming = false
					end
				end
			end
		end
	end
end)

CreateThread(function()
	while true do
		Wait(0)
		if isAiming then
			if not hasShot then
				hasShot = true
				local targetEntity, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(), -1)
				local isShooting = IsControlJustPressed(0, 24)
				if isShooting then
					for k, bodyguard in pairs(Bodyguards) do
						if bodyguard.ped ~= targetPed then
							if bodyguard.inService then
								if IsEntityAPed(targetPed) then
									if not Config.enableBodyguardPlayerDamage then
										if IsPedAPlayer(targetPed) then
											print("Player damage is disabled")
										end
									else
										local isFriend = IsPedInFriendList(targetPed)
										if not isFriend then
											bodyguard.task = "attacking"
											ClearPedTasks(bodyguard.ped)
											TaskCombatPed(bodyguard.ped, targetPed, 0, 16)
											AmmoSyncState = true
											if bodyguard.weapon then
												if not (bodyguard.ammo and bodyguard.ammo > 0) then
													if Config.playersProvideWeapons then
														goto continue
													end
												end
												if not Config.playersProvideWeapons then
													SetPedAmmo(bodyguard.ped, GetHashKey(bodyguard.weapon), 999)
												end
												SetCurrentPedWeapon(bodyguard.ped, GetHashKey(bodyguard.weapon), true)
											end
											::continue::
											SetPedKeepTask(bodyguard.ped, true)
										end
									end
								end
							end
						end
					end
				else
					hasShot = false
				end
			end
		end
	end
end)

local isParking = false

function Park(vehicle, driver)
	if isParking then
		return
	end
	isParking = true
	local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
	local size = maxDim - minDim
	VehOptions.mode = "park"
	
	CreateThread(function()
		HelpText(L("park", {
			key = Config.keyActions.park,
			key2 = Config.keyActions.cancelPark
		}))
		
		while VehOptions.mode == "park" do
			Wait(0)
			local coords = GetWorldCoordsFromScreen()
			DrawMarker(
				1,
				coords.x, coords.y, coords.z,
				0.0, 0.0, 0.0,
				0.0, 0.0, 0.0,
				size, size, 1.0,
				0, 180, 0, 255,
				false, true, 2,
				false, false, false, false
			)
			
			if IsControlPressed(0, Keys[Config.keyActions.park].key) then
				TaskVehicleGotoNavmesh(driver, vehicle, coords.x, coords.y, coords.z, 7.0, 156, 1.15)
			end
			
			if IsControlPressed(0, Keys[Config.keyActions.cancelPark].key) then
				VehOptions.mode = "waypoint"
				isParking = false
				break
			end
		end
		lib.hideTextUI()
	end)
end

function GetPedComponents(ped)
	local components = {}
	for i = 0, 11 do
		local component = {}
		component[1] = GetPedDrawableVariation(ped, i)
		component[2] = GetPedTextureVariation(ped, i)
		component[3] = GetPedPaletteVariation(ped, i)
		component[4] = nil
		component[5] = nil
		components[i] = component
	end
	return components
end

function SetPedComponents(ped, components)
	for i = 1, #components do
		local component = components[i]
		SetPedComponentVariation(ped, i - 1, component[1], component[2], component[3])
	end
end
