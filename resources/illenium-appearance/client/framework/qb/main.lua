if not Framework.QBCore() then return end

local client = client

--- Prefer native QBX (`qbx_core`); fall back to legacy `qb-core` object when that resource is running.
local useQbx = GetResourceState("qbx_core") == "started"
local QBCore

if not useQbx then
    local ok, core = pcall(function()
        return exports["qb-core"]:GetCoreObject()
    end)
    QBCore = ok and core or nil
end

if not useQbx and not QBCore then
    lib.print.error("[illenium-appearance] QB framework: start qbx_core or qb-core before illenium-appearance.")
    return
end

local function getPlayerDataSync()
    if useQbx then
        local ok, data = pcall(function()
            return exports.qbx_core:GetPlayerData()
        end)
        return ok and data or nil
    end
    return QBCore.Functions.GetPlayerData()
end

local PlayerData = getPlayerDataSync() or {}

local function getRankInputValues(rankList)
    local rankValues = {}
    for k, v in pairs(rankList) do
        rankValues[#rankValues + 1] = {
            label = v.name,
            value = k
        }
    end
    return rankValues
end

local function setClientParams()
    if not PlayerData then return end
    client.job = PlayerData.job
    client.gang = PlayerData.gang
    client.citizenid = PlayerData.citizenid
end

function Framework.GetPlayerGender()
    if PlayerData and PlayerData.charinfo and PlayerData.charinfo.gender == 1 then
        return "Female"
    end
    return "Male"
end

function Framework.UpdatePlayerData()
    PlayerData = getPlayerDataSync() or PlayerData or {}
    setClientParams()
end

function Framework.HasTracker()
    local pd = getPlayerDataSync()
    return pd and pd.metadata and pd.metadata["tracker"]
end

function Framework.CheckPlayerMeta()
    local md = PlayerData and PlayerData.metadata
    if not md then return false end
    return md["isdead"] or md["inlaststand"] or md["ishandcuffed"]
end

function Framework.IsPlayerAllowed(citizenid)
    return PlayerData and citizenid == PlayerData.citizenid
end

function Framework.GetRankInputValues(type)
    local grades
    if useQbx then
        if type == "gang" then
            local g = client.gang and exports.qbx_core:GetGang(client.gang.name)
            grades = g and g.grades
        else
            local j = client.job and exports.qbx_core:GetJob(client.job.name)
            grades = j and j.grades
        end
    else
        if type == "gang" then
            local g = QBCore.Shared.Gangs[client.gang.name]
            grades = g and g.grades
        else
            local j = QBCore.Shared.Jobs[client.job.name]
            grades = j and j.grades
        end
    end
    if not grades then
        return {}
    end
    return getRankInputValues(grades)
end

function Framework.GetJobGrade()
    return client.job.grade.level
end

function Framework.GetGangGrade()
    return client.gang.grade.level
end

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
    PlayerData.job = JobInfo
    client.job = JobInfo
    ResetBlips()
end)

RegisterNetEvent("QBCore:Client:OnGangUpdate", function(GangInfo)
    PlayerData.gang = GangInfo
    client.gang = GangInfo
    ResetBlips()
end)

RegisterNetEvent("QBCore:Client:SetDuty", function(duty)
    if PlayerData and PlayerData.job then
        PlayerData.job.onduty = duty
        client.job = PlayerData.job
    end
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    InitAppearance()
end)

RegisterNetEvent("qb-clothes:client:CreateFirstCharacter", function()
    if useQbx then
        PlayerData = exports.qbx_core:GetPlayerData()
        if not PlayerData then
            lib.print.warn("[illenium-appearance] CreateFirstCharacter: PlayerData is nil (qbx_core)")
            return
        end
        setClientParams()
        InitializeCharacter(Framework.GetGender(true))
        return
    end
    QBCore.Functions.GetPlayerData(function(pd)
        PlayerData = pd
        if not PlayerData then
            lib.print.warn("[illenium-appearance] CreateFirstCharacter: PlayerData is nil")
            return
        end
        setClientParams()
        InitializeCharacter(Framework.GetGender(true))
    end)
end)

function Framework.CachePed()
    return nil
end

function Framework.RestorePlayerArmour()
    Framework.UpdatePlayerData()
    if PlayerData and PlayerData.metadata then
        Wait(1000)
        SetPedArmour(cache.ped, PlayerData.metadata["armor"])
    end
end
