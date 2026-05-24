ESX = nil
PlayerData = {}

if Config.framework ~= "esx" then
	return
end

export, ESX = pcall(function()
	return exports.es_extended:getSharedObject()
end)

if not export then
	TriggerEvent("esx:getSharedObject", function(obj)
		ESX = obj
	end)
end

-- CreateThread(function ()
--     Wait(500)
--     LoadBodyguards()
-- end)

RegisterNetEvent("esx:playerLoaded", function(PlayerData)
	PlayerData = ESX.GetPlayerData()

	ESX.PlayerLoaded = true

	LoadBodyguards()
end)

RegisterNetEvent("esx:onPlayerLogout", function()
	ESX.PlayerLoaded = false

	while not ESX.PlayerLoaded do
		Wait(500)
	end

	FrameworkLoaded = true
	LoadBodyguards()
end)

CreateThread(function()
	Wait(500)

	while ESX == nil do
		Wait(500)
	end

	while ESX.GetPlayerData().job == nil do
		Wait(500)
	end

	PlayerData = ESX.GetPlayerData()
	LoadBodyguards()
end)

RegisterNetEvent("esx:setJob", function(job)
	TriggerServerEvent("electus_bodyguards:getPoliceAlerts")
end)

function GetJob()
	while ESX.GetPlayerData().job == nil do
		Wait(0)
	end
	local job = ESX.GetPlayerData().job.name
	return job
end
