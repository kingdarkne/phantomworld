RegisterNUICallback("take_leave", function(data, cb)
	local slot = data.index + 1
	local bodyguard = Bodyguards[slot]
	TakeLeave(bodyguard)
	ToggleNuiFrame(false)
	cb({})
end)

RegisterNUICallback("terminate_contract", function(data, cb)
	local slot = data.index + 1
	-- local bodyguard = bodyguards[slot]
	TriggerEvent("electus_bodyguards:deleteBodyguard", slot)
	TriggerServerEvent("electus_bodyguards:terminateContract", slot)
	ToggleNuiFrame(false)
	cb({})
end)

RegisterNUICallback("change_speed", function(data, cb)
	VehOptions.speed = data.speed
	UpdateVehicle()
	cb({})
end)

RegisterNUICallback("add_friend", function(data, cb)
	ToggleNuiFrame(false)
	SendReactMessage("renderComponent", {
		component = "",
	})
	AddFriend(data.friend)
	cb({})
end)

RegisterNUICallback("remove_friend", function(data, cb)
	ToggleNuiFrame(false)
	SendReactMessage("renderComponent", {
		component = "",
	})
	RemoveFriend(data.friend)
	cb({})
end)

RegisterNUICallback("get_friends", function(data, cb)
	cb(GetFriends())
end)

RegisterNUICallback("get_players", function(data, cb)
	local players = lib.callback.await("electus_bodyguards:getPlayers", false)
	cb(players)
end)

RegisterNUICallback("change_aggressiveness", function(data, cb)
	VehOptions.aggressiveness = data.aggressiveness
	UpdateVehicle()
	cb({})
end)

RegisterNUICallback("purchase", function(data, cb)
	if not Bodyguards[data.slot + 1] then
		TriggerServerEvent(
			"electus_bodyguards:insertBodyguard",
			data.price,
			data.slot + 1,
			data.model,
			data.weapon,
			data.days
		)
	end
	ToggleNuiFrame(false)
	cb({})
end)

RegisterNUICallback("hideFrame", function(_, cb)
	ToggleNuiFrame(false)
	if RecruitTargetPed then
		EndRecruitScene()
	end
	cb({})
end)

RegisterNUICallback("reinstate", function(data, cb)
	local slot = data.index + 1
	local bodyguard = Bodyguards[slot]
	Reinstate(bodyguard)
	ToggleNuiFrame(false)
	cb({})
end)

RegisterNUICallback("get_out", function(data, cb)
	local i = GetPedFromSeat(data.seat)
	local bodyguard = Bodyguards[i]
	local veh = GetVehiclePedIsIn(bodyguard.ped, false)
	TaskLeaveVehicle(bodyguard.ped, veh, 0)
	cb({})
end)

RegisterNUICallback("switch_mode", function(data, cb)
	local mode = data.mode

	if mode then
		VehOptions.mode = "waypoint"
	else
		VehOptions.mode = "wander"
	end

	UpdateVehicle()
	cb({})
end)

RegisterNUICallback("calling_cops", function(data, cb)
	local coords = GetEntityCoords(PlayerPedId())
	local id = math.random(1, 10000000)
	TriggerServerEvent("electus_bodyguards:callCops", id, coords)
	CreateThread(function()
		Wait(5 * 60 * 1000)
		TriggerServerEvent("electus_bodyguards:removePoliceAlert", id)
	end)
end)

RegisterNUICallback("claim_insurance", function(data, cb)
	local slot = data.index + 1
	print(slot)
	local bodyguard = Bodyguards[slot]

	if bodyguard.isDead == 1 then
		bodyguard.isDead = 0
		bodyguard.inService = 1
	else
		DeleteEntity(bodyguard.ped)
		bodyguard.isDead = 0
	end

	TriggerEvent("electus_bodyguards:insertBodyguard", bodyguard)
	TriggerServerEvent("electus_bodyguards:updateBodyguard", bodyguard)
	ToggleNuiFrame(false)
	cb({})
end)
