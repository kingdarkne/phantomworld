local QBCore = QBCore or { Functions = {}, Commands = {}, Shared = { Items = {}, Weapons = {} } }
QBCore.Functions = QBCore.Functions or {}
QBCore.Commands = QBCore.Commands or {}
QBCore.Shared = QBCore.Shared or { Items = {}, Weapons = {} }
QBCore.Functions.GetPlayer = QBCore.Functions.GetPlayer or function(src) return exports.qbx_core:GetPlayer(src) end
QBCore.Functions.GetPlayerByCitizenId = QBCore.Functions.GetPlayerByCitizenId or function(cid) return exports.qbx_core:GetPlayerByCitizenId(cid) end

function GetPlayerData(source)
	local Player = QBCore.Functions.GetPlayer(source)
	if Player == nil then return end -- Player not loaded in correctly
	return Player.PlayerData
end

function UnpackJob(data)
	local job = {
		name = data.name,
		label = data.label
	}
	local grade = {
		name = data.grade.name,
	}

	return job, grade
end

function PermCheck(src, PlayerData)
	local result = true

	if not Config.AllowedJobs[PlayerData.job.name] then
		print(("UserId: %s(%d) tried to access the mdt even though they are not authorised (server direct)"):format(GetPlayerName(src), src))
		result = false
	end

	return result
end

function ProfPic(gender, profilepic)
	if profilepic then return profilepic end;
	if gender == "f" then return "img/female.png" end;
	return "img/male.png"
end

function IsJobAllowedToMDT(job)
	if Config.PoliceJobs[job] then
		return true
	elseif Config.AmbulanceJobs[job] then
		return true
	elseif Config.DojJobs[job] then
		return true
	else
		return false
	end
end

function GetNameFromPlayerData(PlayerData)
	return ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)
end
