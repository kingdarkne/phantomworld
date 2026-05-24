function UpdateVehicle()
	local bodyguard = Bodyguards[VehOptions.driver]
	local veh = GetVehiclePedIsIn(bodyguard.ped, false)
	local drivingStyle = 411

	if VehOptions.aggressiveness >= 0.7 then
		drivingStyle = 787259
	end

	SetDriverAggressiveness(bodyguard.ped, VehOptions.aggressiveness)
	if VehOptions.mode == "wander" then
		TaskVehicleDriveWander(bodyguard.ped, veh, VehOptions.speed + 0.0, drivingStyle)
	elseif VehOptions.mode == "waypoint" then
		local waypoint = GetFirstBlipInfoId(8)
		if waypoint then
			local coords = GetBlipCoords(waypoint)
			TaskVehicleDriveToCoord(
				bodyguard.ped,
				veh,
				coords.x,
				coords.y,
				coords.z,
				VehOptions.speed + 0.0,
				0,
				GetEntityModel(veh),
				drivingStyle,
				20.0
			)
		end
	end
end

CreateThread(function()
	local lastBlip = GetFirstBlipInfoId(8)

	while true do
		Wait(2500)
		if VehOptions.mode == "waypoint" then
			local waypoint = GetFirstBlipInfoId(8)
			if waypoint and VehOptions.driver then
				local bodyguard = Bodyguards[VehOptions.driver]
				local veh = GetVehiclePedIsIn(bodyguard.ped, false)
				local coords = GetBlipCoords(waypoint)
				local lastCoords = GetBlipCoords(lastBlip)
				local drivingStyle = 411

				if VehOptions.aggressiveness >= 0.7 then
					drivingStyle = 787259
				end

				if coords ~= lastCoords then
					lastBlip = waypoint
					TaskVehicleDriveToCoord(
						bodyguard.ped,
						veh,
						coords.x,
						coords.y,
						coords.z,
						VehOptions.speed + 0.0,
						0,
						GetEntityModel(veh),
						drivingStyle,
						20.0
					)
				end
			end
		end
	end
end)

local inVehMenu = false

function OpenVehicleMenu()
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

	if inVehMenu then
		ToggleNuiFrame(false)
	elseif vehicle ~= 0 then
		SendReactMessage("renderComponent", { component = "vehicleMenu" })
		Wait(100)
		SendReactMessage("numberOfSeats", GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)))
		SendReactMessage("setMaxSpeed", GetVehicleEstimatedMaxSpeed(vehicle))
		SendReactMessage("vehicleUpdated", Seats)
		ToggleNuiFrame(true)
	end
end

lib.addKeybind({
	name = "vehbodyguard",
	description = "Vehicle Bodyguard Menu",
	defaultKey = tostring(Config.keyActions.vehicleMenu),
	onPressed = function()
		if GetFirstBodyguardIndex() then
			OpenVehicleMenu()
		end
	end,
})

--NUI events
RegisterNUICallback("task_drive", function(data, cb)
	local targetSeat = data.seat
	local i = GetPedFromSeat(targetSeat)
	local bodyguard = Bodyguards[i]
	local playerPed = PlayerPedId()
	local veh = GetVehiclePedIsIn(bodyguard.ped, false)
	local driver = GetPedInVehicleSeat(veh, -1)

	if driver == bodyguard.ped then
		Park(veh, driver)
		return
	end

	if veh then
		if driver then
			local found = false

			for k, v in pairs(Bodyguards) do
				if v.ped == driver or playerPed == driver then
					found = true
					break
				end
			end

			if found then
				TaskLeaveVehicle(driver, veh, 16)
				local seatFree = IsVehicleSeatFree(veh, -1)

				while not seatFree do
					seatFree = IsVehicleSeatFree(veh, -1)
					Wait(50)
				end

				TaskEnterVehicle(bodyguard.ped, veh, -1, -1, 2.0, 16, 0)

				seatFree = IsVehicleSeatFree(veh, targetSeat)

				while not seatFree do
					seatFree = IsVehicleSeatFree(veh, targetSeat)
					Wait(50)
				end

				TaskEnterVehicle(driver, veh, -1, targetSeat, 2.0, 16, 0)
				VehOptions.driver = bodyguard.slot
				UpdateVehicle()
			end
		else
			TaskEnterVehicle(bodyguard.ped, veh, -1, -1, 2.0, 16, 0)
			VehOptions.driver = bodyguard.slot
			UpdateVehicle()
		end
	end
	cb({})
end)
