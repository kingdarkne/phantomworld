QBCore = nil
PlayerData = {}

if Config.framework ~= "qb" then
	return
end

QBCore = exports["qb-core"]:GetCoreObject() or exports.qbx_core:GetCoreObject()

CreateThread(function()
	Wait(1000)

	if LocalPlayer.state.isLoggedIn then
		LoadBodyguards()
	end
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
	LoadBodyguards()
	PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
	TriggerServerEvent("electus_bodyguards:getPoliceAlerts")
end)

function GetJob()
	local job = QBCore.Functions.GetPlayerData().job.name
	return job
end
