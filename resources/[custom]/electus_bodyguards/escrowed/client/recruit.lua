local recruitedPeds = {}
local recruitCamera = nil
RecruitTargetPed = nil

function StartRecruitScene(ped)
	local playerPed = PlayerPedId()
	local offsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
	
	NetworkRequestControlOfEntity(ped)
	while not NetworkHasControlOfEntity(ped) do
		Wait(250)
	end
	
	recruitedPeds[ped] = true
	RecruitTargetPed = ped
	
	SetEntityCoords(ped, offsetCoords.x, offsetCoords.y, offsetCoords.z - 1.0)
	SetEntityHeading(ped, GetEntityHeading(playerPed) - 180.0)
	FreezeEntityPosition(ped, true)
	
	local headBone = GetPedBoneIndex(ped, 31086)
	recruitCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	SetCamActive(recruitCamera, true)
	RenderScriptCams(true, true, 500, true, true)
	AttachCamToPedBone(recruitCamera, ped, headBone, 0.5, 1.75, 0.75, true)
	PointCamAtPedBone(recruitCamera, ped, headBone, 0.0, 0.0, 0.5, true)
	SetCamFov(recruitCamera, 50.0)
	
	ClearPedTasksImmediately(ped)
	ClearPedTasks(ped)
	SetBlockingOfNonTemporaryEvents(RecruitTargetPed, true)
	TaskSetBlockingOfNonTemporaryEvents(RecruitTargetPed, true)
	TaskTurnPedToFaceEntity(ped, playerPed, -1)
	TaskStandStill(ped, -1)
	SetPedKeepTask(ped, true)
	
	SendReactMessage("renderComponent", {
		component = "npcDialog",
	})
	ToggleNuiFrame(true)
end

if Config.targetSystem ~= "none" then
	exports.qtarget:Ped({
		options = {
			{
				icon = "fas fa-person-rifle",
				label = L("recruit"),
				action = function(entity)
					StartRecruitScene(entity)
				end,
				canInteract = function(entity)
					local pedType = GetPedType(entity)
					local isAcceptedModel = Config.acceptedModelsForStreetRecruitment[GetEntityModel(entity)]
					local isMissionEntity = IsEntityAMissionEntity(entity)
					local script = GetEntityScript(entity)
					local isRecruited = recruitedPeds[entity]
					return (pedType == 4 or pedType == 5 or (pedType > 7 and pedType < 19)) and isAcceptedModel and not isMissionEntity and script == "" and isRecruited
				end,
			}
		},
		distance = 2
	})
end

RegisterNUICallback("successfully_recruit", function(data, cb)
	EndRecruitScene()
	local ped = RecruitTargetPed
	local model = GetEntityArchetypeName(ped)
	local pedType = GetPedType(ped)
	local coords = GetEntityCoords(ped)
	local heading = GetEntityHeading(ped)
	
	local bodyguards = lib.callback.await("electus_bodyguards:getBodyguards", false)
	if #bodyguards >= Config.maxSlots then
		Notify(L("maxSlots"), "error")
		cb({})
		return
	end
	
	local price = data.price
	local days = data.days
	
	if price < Config.recruit.recruitPriceRange.min or
		days < Config.recruit.recruitDaysRange.min or
		price > Config.recruit.recruitPriceRange.max or
		days > Config.recruit.recruitDaysRange.max then
		Notify(L("invalidPriceOrDays"), "error")
		cb({})
		return
	end
	
	local recruitData = {}
	recruitData.components = GetPedComponents(ped)
	recruitData.model = model
	recruitData.days = days
	recruitData.price = price
	
	local result = lib.callback.await("electus_bodyguards:recruit", false, recruitData)
	
	if result then
		Notify(L("recruitSuccess"), "success")
		NetworkRequestControlOfEntity(ped)
		while not NetworkHasControlOfEntity(ped) do
			Wait(250)
		end
		
		local shooting = Config.recruitStats.shooting
		local driving = Config.recruitStats.driving
		local armor = Config.recruitStats.armor
		
		PlaceObjectOnGroundProperly(ped)
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
		
		Bodyguards[result.slot] = {
			ped = ped,
			slot = result.slot,
			model = model,
			weapon = nil,
			ammo = nil,
			time = result.time,
			days = result.days,
			isDead = result.isDead,
			inService = result.inService,
			isBackup = result.isBackup,
			components = GetPedComponents(ped),
		}
		
		if Config.targetSystem ~= "none" then
			exports["qtarget"]:AddTargetEntity(Bodyguards[result.slot].ped, {
				options = {
					{
						label = L("interact"),
						action = function()
							InteractBodyguard(Bodyguards[result.slot])
						end,
					},
				},
				distance = 2,
			})
		end
	end
	
	cb({})
end)

RegisterNUICallback("end_recruit", function(data, cb)
	EndRecruitScene()
	cb({})
end)

RegisterNUICallback("emote_no", function(data, cb)
	cb({})
end)

RegisterNUICallback("emote_yes", function(data, cb)
	cb({})
end)

function EndRecruitScene()
	ToggleNuiFrame(false)
	RenderScriptCams(false, true, 500, true, false)
	DestroyCam(recruitCamera, false)
	ClearPedTasks(RecruitTargetPed)
	FreezeEntityPosition(RecruitTargetPed, false)
	SendReactMessage("renderComponent", {})
	recruitCamera = nil
end

local policeAlerts = {}

function FindAlertIndex(id)
	for i = 1, #policeAlerts do
		if policeAlerts[i].id == id then
			return true, i
		end
	end
	return false
end

RegisterNetEvent("electus_bodyguards:alertPolice", function(id, coords)
	if lib.table.contains(Config.policeJobs, GetJob()) then
		local found, index = FindAlertIndex(id)
		if found then
			return
		end
	end
	
	local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
	local alertIndex = #policeAlerts + 1
	policeAlerts[alertIndex] = {
		id = id,
		coords = coords,
		blip = blip,
	}
	
	SetBlipSprite(blip, 161)
	SetBlipColour(blip, 1)
	SetBlipScale(blip, 1.5)
	SetBlipAsShortRange(blip, false)
	SetBlipDisplay(blip, 2)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(L("dispatch_label"))
	EndTextCommandSetBlipName(blip)
	Notify(L("recruitment_dispatch"), "info")
end)

RegisterNetEvent("electus_bodyguards:removePoliceAlert", function(id)
	local found, index = FindAlertIndex(id)
	if not found then
		return
	end
	
	RemoveBlip(policeAlerts[index].blip)
	table.remove(policeAlerts, index)
end)
