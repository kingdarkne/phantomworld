Bodyguards = {}
RelationHash = nil
VehOptions = {
	speed = 0.0,
	aggressiveness = 0,
	mode = "wander",
	driver = nil,
}
AmmoSyncState = false

function LoadBodyguards()
	RefreshPedShop()
	local bodyguards = lib.callback.await("electus_bodyguards:getBodyguards", false)
	local ret, hash = AddRelationshipGroup("bodyguards_" .. GetPlayerPed(-1))
	RelationHash = hash

	if Config.enableBodyguardFriendlyFire == false then
		SetEntityCanBeDamagedByRelationshipGroup(PlayerPedId(), false, RelationHash)
	end

	SetRelationshipBetweenGroups(2, RelationHash, GetHashKey("PLAYER"))
	SetRelationshipBetweenGroups(2, GetHashKey("PLAYER"), RelationHash)

	for k, v in pairs(bodyguards) do
		if v.components and type(v.components) == "string" then
			v.components = json.decode(v.components)
		end
		TriggerEvent("electus_bodyguards:insertBodyguard", v)
	end
	SendReactMessage("setOwnedPeds", bodyguards)
end

AddEventHandler("entityDamaged", function(victim, culprit, weapon, baseDamage)
	local ped = PlayerPedId()

	for k, v in pairs(Bodyguards) do
		if
			(v.inService and DoesEntityExist(v.ped) and ped == victim or v.ped == victim)
			and (ped ~= culprit and v.ped ~= culprit)
		then
			if not Config.enableBodyguardPlayerDamage and IsPedAPlayer(culprit) then
				print("Player damage is disabled")
			else
				local isFriend = IsPedInFriendList(culprit)
				if not isFriend and v.task ~= "guarding" then
					v.task = "attacking"
					TaskCombatPed(v.ped, culprit, 0, 16)
					AmmoSyncState = true
					if v.weapon and (v.ammo and v.ammo > 0 or not Config.playersProvideWeapons) then
						if Config.debug then
							print(v.weapon, v.ammo)
						end
						if not Config.playersProvideWeapons then
							SetPedAmmo(v.ped, GetHashKey(v.weapon), 999)
						end
						SetCurrentPedWeapon(v.ped, GetHashKey(v.weapon), true)
					end
					SetPedKeepTask(v.ped, true)
				end
			end
		end

		local health = GetEntityHealth(v.ped)
		if health <= 0 and v.inService == 1 and DoesEntityExist(v.ped) then
			DeleteEntity(v.ped)

			while DoesEntityExist(v.ped) do
				Wait(100)
			end

			v.ped = nil
			v.isDead = 1
			v.inService = 0
			TriggerServerEvent("electus_bodyguards:updateBodyguard", v)
		end
	end
end)

-- Spawns he bodyguard from server side and sets it to client side
function InsertBodyguard(bodyguard)
	local model = bodyguard.model
	local modelIndex, type = GetModelIndex(model)
	local shooting = 0
	local driving = 0
	local armor = 0

	if bodyguard.isRecruit then
		shooting = Config.recruitStats.shooting
		driving = Config.recruitStats.driving
		armor = Config.recruitStats.armor
	else
		shooting = Config.shop[type][modelIndex].shooting
		driving = Config.shop[type][modelIndex].driving
		armor = Config.shop[type][modelIndex].armor
	end

	if bodyguard.inService == 1 and bodyguard.isDead == 0 then
		lib.requestModel(model)
		local pedNet = lib.callback.await("electus_bodyguards:createBodyguard", false, model)

		while not NetworkDoesNetworkIdExist(pedNet) do
			Wait(0)
		end

		while not NetworkHasControlOfNetworkId(pedNet) do
			NetworkRequestControlOfNetworkId(pedNet)
			Wait(500)
		end

		lib.callback.await("electus_bodyguards:disableControlFilter", false, pedNet)

		local ped = NetworkGetEntityFromNetworkId(pedNet)

		if bodyguard.components then
			SetPedComponents(ped, bodyguard.components)
		else
			local newComponents = GetPedComponents(ped)
			bodyguard.components = newComponents

			lib.callback.await("electus_bodyguards:updateBodyguard", false, bodyguard)
		end

		if bodyguard.weapon then
			local gunHash = GetHashKey(bodyguard.weapon)
			GiveWeaponToPed(ped, gunHash, bodyguard.ammo, true, false)
			SetCurrentPedWeapon(ped, gunHash, true)
		end

		PlaceObjectOnGroundProperly(ped)
		SetEntityAsMissionEntity(ped, true, true)
		SetBlockingOfNonTemporaryEvents(ped, true)

		SetPedCombatAttributes(ped, 5, true)
		SetPedCombatAttributes(ped, 13, true)
		SetPedCombatAttributes(ped, 21, true)
		SetPedCombatAttributes(ped, 50, true)
		SetPedCombatAttributes(ped, 0, false)

		SetPedFleeAttributes(ped, 0, false)
		SetPedAccuracy(ped, shooting * 3 * 10)
		SetDriverAbility(ped, driving * 0.3)
		SetPedArmour(ped, armor * 33)
		SetPedDropsWeaponsWhenDead(ped, false)
		SetEntityHealth(ped, 200.0)
		SetNetworkIdCanMigrate(PedToNet(ped), false)
		SetPedRelationshipGroupHash(ped, RelationHash)
		SetCurrentPedWeapon(ped, 0xA2719263, true)

		Bodyguards[bodyguard.slot] = {
			ped = ped,
			slot = bodyguard.slot,
			model = model,
			weapon = bodyguard.weapon,
			ammo = bodyguard.ammo,
			time = bodyguard.time,
			days = bodyguard.days,
			isDead = bodyguard.isDead,
			inService = bodyguard.inService,
			isBackup = bodyguard.isBackup,
			isRecruit = bodyguard.isRecruit,
			components = bodyguard.components,
		}
		SetEntityCoords(ped, GetEntityCoords(PlayerPedId()))
	else
		Bodyguards[bodyguard.slot] = {
			ped = nil,
			slot = bodyguard.slot,
			model = model,
			weapon = bodyguard.weapon,
			ammo = bodyguard.ammo,
			time = bodyguard.time,
			days = bodyguard.days,
			isDead = bodyguard.isDead,
			inService = bodyguard.inService,
			isBackup = bodyguard.isBackup,
			isRecruit = bodyguard.isRecruit,
			components = bodyguard.components,
		}
	end

	if Config.targetSystem ~= "none" then
		exports["qtarget"]:AddTargetEntity(Bodyguards[bodyguard.slot].ped, {
			options = {
				{
					label = L("interact"),
					action = function()
						InteractBodyguard(Bodyguards[bodyguard.slot])
					end,
				},
			},
			distance = 2,
		})
	end

	return Bodyguards[bodyguard.slot]
end

RegisterNetEvent("electus_bodyguards:insertBodyguard", function(bodyguard)
	InsertBodyguard(bodyguard)
end)

CreateThread(function()
	while true do
		Wait(60000)
		if AmmoSyncState then
			AmmoSyncState = false
			for k, v in pairs(Bodyguards) do
				v.ammo = GetAmmoInPedWeapon(v.ped, GetHashKey(v.weapon))
				TriggerServerEvent("electus_bodyguards:updateBodyguard", v)
			end
		end
	end
end)

--general handle
CreateThread(function()
	local wait = 1000
	local textActivated = false

	while true do
		Wait(wait)
		if GetNumBodyguards() > 0 then
			for k, bodyguard in pairs(Bodyguards) do
				if
					bodyguard.task
					and (
						bodyguard.task ~= "driving"
						and bodyguard.task ~= "stayPut"
						and bodyguard.task ~= "guarding"
						and bodyguard.inService
						and bodyguard.task ~= "backupDriving"
					)
				then
					if not textActivated then
						HelpText(L("cancelTask", { ["key"] = Config.keyActions.cancel }))
						textActivated = true
					end
					wait = 0
					if IsControlJustPressed(0, Keys[Config.keyActions.cancel].key) then
						for k, v in pairs(Bodyguards) do
							v.task = nil
							SetCurrentPedWeapon(v.ped, 0xA2719263, true)
							ClearPedTasks(v.ped)
							ClearPedTasksImmediately(v.ped)
							ClearPedSecondaryTask(v.ped)
						end
					end
				else
					textActivated = false
					local isOpen, text = lib.isTextUIOpen()
					if text == L("cancelTask", { ["key"] = Config.keyActions.cancel }) then
						lib.hideTextUI()
					end
					wait = 1000
				end
			end
		end
	end
end)

RegisterNetEvent("electus_bodyguards:deleteBodyguard", function(slot)
	if tonumber(slot) and Bodyguards[tonumber(slot)] then
		local bodyguard = Bodyguards[tonumber(slot)]
		local ped = bodyguard.ped
		DeleteEntity(ped)
		Bodyguards[tonumber(slot)] = nil
	end
end)

function HasItem(item)
	if not item then
		return false
	end

	local hasItem = lib.callback.await("electus_bodyguards:hasItem", false, item)

	return hasItem
end

function InteractBodyguard(bodyguard)
	lib.registerMenu({
		id = "weapon_menu",
		title = L("weaponMenu"),
		position = "top-right",
		options = {},
	}, function(selected, scrollIndex, args)
		local val = args.value

		if val == "removeWeapon" then
			RemoveWeapon(bodyguard)
		elseif val == "giveWeapon" then
			GiveWeapon(bodyguard)
		elseif val == "giveAmmo" then
			GiveAmmo(bodyguard)
		elseif val == "removeAmmo" then
			RemoveAmmo(bodyguard)
		end
	end)

	local options = {}

	if bodyguard.task == "stayPut" then
		options[#options + 1] = { label = L("follow"), args = { value = "follow" } }
	else
		options[#options + 1] = { label = L("stayPut"), args = { value = "stayPut" } }
	end

	if bodyguard.task == "guarding" then
		options[#options + 1] = { label = L("stopGuarding"), args = { value = "stopGuarding" } }
	else
		options[#options + 1] = { label = L("startGuarding"), args = { value = "startGuarding" } }
	end

	options[#options + 1] = { label = L("takeLeave"), args = { value = "takeLeave" } }

	lib.registerMenu({
		id = "interact_bodyguard",
		title = L("bodyguardMenu"),
		position = "top-right",
		options = options,
	}, function(selected, scrollIndex, args)
		local val = args.value

		if val == "takeLeave" then
			TakeLeave(bodyguard)
		elseif val == "follow" or val == "stayPut" then
			SwitchStayPut(bodyguard)
		elseif val == "weaponMenu" then
			lib.showMenu("weapon_menu")
		elseif val == "startGuarding" then
			StartGuard(bodyguard)
		elseif val == "stopGuarding" then
			StopGuarding(bodyguard)
		end
	end)

	if Config.playersProvideWeapons and not bodyguard.isBackup then
		lib.setMenuOptions("interact_bodyguard", { label = L("weaponMenu"), args = { value = "weaponMenu" } }, 3)
		if bodyguard.weapon then
			lib.setMenuOptions("weapon_menu", { label = L("removeWeapon"), args = { value = "removeWeapon" } }, 1)
			lib.setMenuOptions("weapon_menu", { label = L("giveAmmo"), args = { value = "giveAmmo" } }, 2)
		else
			lib.setMenuOptions("weapon_menu", { label = L("giveWeapon"), args = { value = "giveWeapon" } }, 1)
		end

		if bodyguard.ammo and bodyguard.ammo > 0 then
			local pedAmmo = GetAmmoInPedWeapon(bodyguard.ped, GetHashKey(bodyguard.weapon))

			lib.setMenuOptions(
				"weapon_menu",
				{ label = L("removeAmmo", { ["ammo"] = pedAmmo }), args = { value = "removeAmmo" } },
				3
			)
		end
	end

	lib.showMenu("interact_bodyguard")
end

function GiveWeapon(bodyguard)
	local options = {}

	for k, v in pairs(Config.weaponConfiguration) do
		if HasItem(k) then
			options[#options + 1] = { label = k, args = { value = k } }
		end
	end

	if #options == 0 then
		Notify(L("noWeapon"), "error")
		return
	end

	lib.registerMenu({
		id = "give_weapon",
		title = L("giveWeapon"),
		position = "top-right",
		options = options,
	}, function(selected, scrollIndex, args)
		local val = args.value

		if val then
			local hasGiven = lib.callback.await("electus_bodyguards:giveWeapon", false, bodyguard, val)
			if hasGiven then
				bodyguard.weapon = val
				GiveWeaponToPed(bodyguard.ped, GetHashKey(val), 0, true, false)
				-- SetCurrentPedWeapon(bodyguard.ped, GetHashKey(val), true)
			end
		end
	end)

	lib.showMenu("give_weapon")
end

function GiveAmmo(bodyguard)
	local input = lib.inputDialog(L("giveAmmo"), { L("ammoAmount") })

	if input then
		local addAmount = tonumber(input[1])
		local ammo = Config.weaponConfiguration[bodyguard.weapon].ammoName
		local hasGiven = lib.callback.await("electus_bodyguards:giveAmmo", false, bodyguard, ammo, addAmount)

		if hasGiven then
			Notify(L("ammoGiven", { ["ammo"] = addAmount }), "success")
			bodyguard.ammo = bodyguard.ammo + addAmount
			AddAmmoToPed(bodyguard.ped, GetHashKey(bodyguard.weapon), addAmount)
		end
	end
end

function RemoveAmmo(bodyguard)
	local pedAmmo = GetAmmoInPedWeapon(bodyguard.ped, GetHashKey(bodyguard.weapon))
	local hasRemoved = lib.callback.await("electus_bodyguards:removeAmmo", false, bodyguard, pedAmmo)
	if hasRemoved then
		bodyguard.ammo = 0
		SetPedAmmo(bodyguard.ped, GetHashKey(bodyguard.weapon), 0)
	end
end

function RemoveWeapon(bodyguard)
	if bodyguard.ammo and bodyguard.ammo > 0 then
		RemoveAmmo(bodyguard)
	end
	local hasRemoved = lib.callback.await("electus_bodyguards:removeWeapon", false, bodyguard)
	if hasRemoved then
		bodyguard.weapon = nil
		SetCurrentPedWeapon(bodyguard.ped, 0, true)
		RemoveWeaponFromPed(bodyguard.ped, GetHashKey(bodyguard.weapon))
	end
end

function Reinstate(bodyguard)
	if bodyguard.inService == 0 then
		bodyguard.inService = 1
		TriggerEvent("electus_bodyguards:insertBodyguard", bodyguard)
		TriggerServerEvent("electus_bodyguards:updateBodyguard", bodyguard)
	end
end

function TakeLeave(bodyguard)
	if bodyguard.inService == 1 then
		bodyguard.inService = 0
		TriggerServerEvent("electus_bodyguards:updateBodyguard", bodyguard)
		bodyguard.task = "leaving"
		TaskSmartFleePed(bodyguard.ped, PlayerPedId(), 1000.0, -1, false, false)

		Wait(10000)
		bodyguard.task = nil
		DeleteEntity(bodyguard.ped)
		while DoesEntityExist(bodyguard.ped) do
			Wait(50)
		end

		bodyguard.ped = nil
	end
end

AddEventHandler("playerDropped", function(reason)
	for k, v in pairs(Bodyguards) do
		if not v.components then
			v.components = json.encode(GetPedComponents(v.ped))
		end
		-- lib.callback.await("electus_bodyguards:updateBodyguard", false, v)
		DeleteEntity(v.ped)
	end
end)

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	for k, v in pairs(Bodyguards) do
		if not v.components then
			v.components = GetPedComponents(v.ped)
		end
		-- lib.callback.await("electus_bodyguards:updateBodyguard", false, v)
		DeleteEntity(v.ped)
	end

	ToggleNuiFrame(false)
end)
