AnimationList = json.decode(LoadResourceFile(GetCurrentResourceName(), "animations.json"))
CurrentAnimation = nil
PlayerProps = {}
PlayerParticles = {}
SecondPropEmote = false

function FindEmote(emoteName)
	for _, emote in ipairs(AnimationList) do
		if emote.name == emoteName then
			return emote
		end
	end
end

function EmoteCommand(_, args, _)
	local emoteName = args[1]

	if emoteName then
		PlayEmote(emoteName)
	else
		toggleMenu()
	end
end

CreateThread(function()
	RegisterCommand('e', EmoteCommand, false)
	RegisterCommand('emote', EmoteCommand, false)
	RegisterKeyMapping("e", 'Open Emote Menu', 'keyboard', AK4Y.MenuKey)

	TriggerEvent('chat:addSuggestion', '/e', 'Play an emote',
		{ { name = "emotename", help = "dance, camera, sit or any valid emote." } })
	TriggerEvent('chat:addSuggestion', '/emote', 'Play an emote',
		{ { name = "emotename", help = "dance, camera, sit or any valid emote." } })

	local expression = GetResourceKvpString("ak4y_emotes:expression")

	if expression then
		SetFacialIdleAnimOverride(PlayerPedId(), expression)
	end

	local walkStyle = GetResourceKvpString("ak4y_emotes:walkStyle")

	if walkStyle then
		LoadAnimSet(walkStyle)
		SetPedMovementClipset(PlayerPedId(), walkStyle, 0.2)
		RemoveAnimSet(walkStyle)
	end

	while true do
		local sleep = 1000

		if CurrentAnimation and not IsPauseMenuActive() then
			sleep = 0
			local ped = PlayerPedId()

			if IsPedShooting(ped) then
				CancelEmote()
			end

			if IsControlPressed(0, 47) and CurrentAnimation.ptfx then
				PtfxStart()
				Wait(500)
				PtfxStop()
			end
		end

		Wait(sleep)
	end
end)

function PlayEmote(emoteName, ped, target)
	local emote = FindEmote(emoteName)

	if not emote then return end

	toggleMenu(false)
	ped = ped or PlayerPedId()

	if emote.category == "expression" then
		if emote.anim == "normal" then
			ClearFacialIdleAnimOverride(ped)
			DeleteResourceKvp("ak4y_emotes:expression")
			return
		end

		SetFacialIdleAnimOverride(ped, emote.anim)
		SetResourceKvp("ak4y_emotes:expression", emote.anim)
	elseif emote.category == "walk" then
		if emote.anim == "default" then
			ResetPedMovementClipset(ped, 0.2)
			DeleteResourceKvp("ak4y_emotes:walkStyle")
			return
		end

		LoadAnimSet(emote.anim)
		SetPedMovementClipset(ped, emote.anim, 0.2)
		RemoveAnimSet(emote.anim)
		SetResourceKvp("ak4y_emotes:walkStyle", emote.anim)
	elseif emote.category == "shared" and not target then
		local closestPlayer, closestDist = GetClosestPlayer()

		if not closestPlayer or closestDist >= AK4Y.MaxDistanceForSharedEmotes then
			AK4Y.Notify(_U("no_players_nearby"), _U("error"), "error")

			return
		end

		TriggerServerEvent("ak4y_emotes:request", closestPlayer, emote.name, emote.target_emote, emote.label)

		AK4Y.Notify(_U("emote_request_sent"), _U("info"), "info")
	else
		local inVehicle = IsPedInAnyVehicle(ped, true)

		if not AK4Y.AllowedInCars and inVehicle then
			return
		end

		if ped == PlayerPedId() then
			CancelEmote()

			if IsPedArmed(ped, 7) then
				SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
			end
		end

		if emote.dict == "Scenario" then
			TaskStartScenarioInPlace(ped, emote.anim, 0, true)
		else
			local flag = 0

			if not inVehicle and emote.options then
				if emote.options.loop then
					flag += 1
				end

				if emote.options.moving then
					flag += 48
				end

				if emote.options.stuck then
					flag += 2
				end
			end

			local duration = emote.options and emote.options.duration or -1

			if emote.props then
				Wait(duration)

				for _, prop in ipairs(emote.props) do
					local p1, p2, p3, p4, p5, p6 = table.unpack(prop.placement)

					AddPropToPed(ped, prop.model, prop.bone, p1, p2, p3, p4, p5, p6)
				end
			end

			if target and target ~= -1 then
				local targetEmote = FindEmote(emote.target_emote)
				local attach = emote.attach or targetEmote.attach

				if attach then
					local bone = GetPedBoneIndex(target, attach.bone or 0)

					AttachEntityToEntity(ped, target, bone, attach.xPos or 0.0,
						attach.yPos or 0.0,
						attach.zPos or 0.0,
						attach.xRot or 0.0,
						attach.yRot or 0.0, attach.zRot or 0.0, false, false, false, true, 0,
						true)
				else
					local offset = emote.offset or targetEmote.offset

					function CalculatePos()
						local offX, offY, offZ, offW = 0.0, 1.0, 0.0, GetEntityHeading(target) + 180.0

						if offset then
							offX, offY, offZ, offW = offset.x or 0.0, offset.y or 1.0,
								offset.z or 0.0, offset.w or offW
						end

						local coords = GetOffsetFromEntityInWorldCoords(target, offX, offY, offZ)

						SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, true)
						SetEntityHeading(ped, offW + 0.0)
						FreezeEntityPosition(ped, true)
					end

					CalculatePos()

					CreateThread(function()
						while IsInPreview do
							CalculatePos()

							Wait(0)
						end
					end)
				end
			end

			LoadAnimDict(emote.dict)
			TaskPlayAnim(ped, emote.dict, emote.anim, 8.0, 8.0, duration, flag, 0.0, false, false, false)
			RemoveAnimDict(emote.dict)
		end

		if ped == PlayerPedId() then
			CurrentAnimation = emote
		end
	end
end

exports("PlayEmote", PlayEmote)
RegisterNuiCallback("playEmote", function(emoteName)
	PlayEmote(emoteName)
end)

RegisterCommand("cancel_emote", function()
	if CurrentAnimation then
		CancelEmote()
	elseif AK4Y.CancelHandsUp then
		PlayEmote("handsup")
	end
end, false)
RegisterKeyMapping("cancel_emote", 'Cancel Emote', 'keyboard', AK4Y.CancelKey)

for i = 1, 7 do
	RegisterCommand("e" .. i, function()
		if IsDisabledControlPressed(0, AK4Y.ShortcutKey) then
			Wait(250)
			SendNUIMessage({
				action = 'playerUseShortcut',
				usedKey = i
			})
		
		end
	end, false)

	RegisterKeyMapping("e" .. i, 'Play Saved Emote ' .. tostring(i), 'keyboard', tostring(i))
end

local lastRequest

RegisterCommand("accept_emote", function()
	if lastRequest then
		TriggerServerEvent("ak4y_emotes:response", lastRequest, true)
		lastRequest = nil
		SendNUIMessage({
			action = 'closeRequest'
		})
	end
end, false)

RegisterCommand("deny_emote", function()
	if lastRequest then
		TriggerServerEvent("ak4y_emotes:response", lastRequest, false)
		lastRequest = nil
		SendNUIMessage({
			action = 'closeRequest'
		})
	end
end, false)

RegisterKeyMapping("accept_emote", 'Accept Emote Request', 'keyboard', AK4Y.AnimationAcceptKey)
RegisterKeyMapping("deny_emote", 'Deny Emote Request', 'keyboard', AK4Y.AnimationDeclineKey)

RegisterNetEvent("ak4y_emotes:sendRequest", function(request)
	AK4Y.Notify(_U("emote_request_received"), _U("info"), "info")

	SendNUIMessage({
		action = 'getRequest',
		senderData = request,
	})

	lastRequest = request
end)

RegisterNetEvent("ak4y_emotes:playSharedEmote", function(emoteName, targetPed)
	PlayEmote(emoteName, nil, targetPed == -1 and targetPed or NetToPed(targetPed))
end)

exports("CancelEmote", CancelEmote)
RegisterNetEvent("ak4y_emotes:cancelEmote", CancelEmote)

exports("GetPlayingEmote", function()
	return CurrentAnimation
end)

RegisterNetEvent("ak4y_emotes:notify", function(msg, desc, type)
	AK4Y.Notify(msg, desc, type)
end)

function GetClosestPlayer()
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local peds = GetGamePool("CPed")
	local closest, closestDist = nil, 0

	for _, targetPed in ipairs(peds) do
		if IsPedAPlayer(targetPed) and targetPed ~= ped then
			local targetCoords = GetEntityCoords(targetPed)
			local distance = #(coords - targetCoords)

			if closest == nil or distance < closestDist then
				closest, closestDist = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed)), distance
			end
		end
	end

	return closest, closestDist
end

function LoadAnimDict(dict)
	local timer = GetGameTimer()

	while GetGameTimer() - timer < 2500 and not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(0)
	end
end

function LoadAnimSet(name)
	local timer = GetGameTimer()

	while GetGameTimer() - timer < 2500 and not HasAnimSetLoaded(name) do
		RequestAnimSet(name)
		Wait(0)
	end
end

function LoadModel(model)
	local timer = GetGameTimer()

	while GetGameTimer() - timer < 2500 and not HasModelLoaded(model) do
		RequestModel(model)
		Wait(0)
	end
end

function CancelEmote(ped)
	if CurrentAnimation then
		ped = ped or PlayerPedId()

		DetachEntity(ped, true, true)
		SetEntityCollision(ped, true, true)
		FreezeEntityPosition(ped, false)


		if CurrentAnimation.dict == "Scenario" then
			ClearPedTasksImmediately(ped)
			ClearAreaOfObjects(GetEntityCoords(ped), 3.0, 0)
		else
			PtfxStop()
			ClearPedTasks(ped)
			DestroyAllProps()
		end

		if CurrentAnimation.category == "shared" then
			TriggerServerEvent("ak4y_emotes:cancelShared")
		end


		CurrentAnimation = nil
	end
end

function AddPropToPed(ped, model, bone, off1, off2, off3, rot1, rot2, rot3)
	LoadModel(model)

	local x, y, z = table.unpack(GetEntityCoords(ped))

	local prop = CreateObject(GetHashKey(model), x, y, z + 0.2, ped == PlayerPedId(), true, true)

	AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), off1, off2, off3, rot1, rot2, rot3, true, true,
		true, true, 1, true)

	if ped == PlayerPedId() then
		table.insert(PlayerProps, prop)
	else
		table.insert(FakeProps, prop)
		SetEntityAlpha(prop, 150, true)
	end
end

function DestroyAllProps()
	for _, prop in pairs(PlayerProps) do
		DeleteEntity(prop)
	end

	PlayerProps = {}
end

function PtfxStart()
	local ptfx = CurrentAnimation.ptfx
	local ptfxAt = ptfx.no_prop and PlayerPedId() or PlayerProps[1]
	local p1, p2, p3, p4, p5, p6 = table.unpack(ptfx.placement)

	UseParticleFxAssetNextCall(ptfx.asset)

	local particle = StartNetworkedParticleFxLoopedOnEntityBone(ptfx.name, ptfxAt, p1, p2, p3, p4, p5, p6,
		GetEntityBoneIndexByName(ptfx.name, "VFX"), 1065353216, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)

	SetParticleFxLoopedColour(particle, 1.0, 1.0, 1.0)

	table.insert(PlayerParticles, particle)
end

function PtfxStop()
	for _, particle in pairs(PlayerParticles) do
		StopParticleFxLooped(particle, false)
	end

	PlayerParticles = {}
end

UILoaded = false
UIOpen = false

function toggleMenu(override)
	if not UILoaded then return end

	if type(override) == "boolean" then
		UIOpen = override
	else
		UIOpen = not UIOpen
	end

	SetNuiFocus(UIOpen, UIOpen)
	SendNUIMessage({
		action = 'display',
		payload = UIOpen
	})
end

RegisterCommand("emotes", function()
	toggleMenu()
end, false)

RegisterNuiCallback("closeMenu", function()
	toggleMenu(false)
end)


RegisterNuiCallback('loaded', function(_, cb)
	UILoaded = true

	cb({
		locales = Locales[AK4Y.Language],
		animationList = AnimationList,
	})
end)


RegisterCommand('anim',function()
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = 'display',
		payload = true
	})
end)