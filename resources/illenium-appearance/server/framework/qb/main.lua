if not Framework.QBCore() then return end

--- Prefer native QBX (`qbx_core`); fall back to legacy `qb-core` GetCoreObject.
local useQbx = GetResourceState("qbx_core") == "started"
local QBCore

if not useQbx then
    local ok, core = pcall(function()
        return exports["qb-core"]:GetCoreObject()
    end)
    QBCore = ok and core or nil
end

if not useQbx and not QBCore then
    print("^1[illenium-appearance] QB framework: start qbx_core or qb-core before illenium-appearance.^7")
    return
end

local function getPlayer(src)
    if useQbx then
        return exports.qbx_core:GetPlayer(src)
    end
    return QBCore.Functions.GetPlayer(src)
end

function Framework.GetPlayerID(src)
    local Player = getPlayer(src)
    if Player then
        return Player.PlayerData.citizenid
    end
end

function Framework.HasMoney(src, moneyType, money)
    local Player = getPlayer(src)
    if not Player or not Player.PlayerData or not Player.PlayerData.money then
        return false
    end
    local balance = Player.PlayerData.money[moneyType]
    return type(balance) == "number" and balance >= money
end

function Framework.RemoveMoney(src, moneyType, money)
    local Player = getPlayer(src)
    if not Player then
        return false
    end
    return Player.Functions.RemoveMoney(moneyType, money)
end

function Framework.GetJob(src)
    local Player = getPlayer(src)
    return Player and Player.PlayerData.job
end

function Framework.GetGang(src)
    local Player = getPlayer(src)
    return Player and Player.PlayerData.gang
end

function Framework.SaveAppearance(appearance, citizenID)
    Database.PlayerSkins.UpdateActiveField(citizenID, 0)
    Database.PlayerSkins.DeleteByModel(citizenID, appearance.model)
    Database.PlayerSkins.Add(citizenID, appearance.model, json.encode(appearance), 1)
end

function Framework.GetAppearance(citizenID, model)
    local result = Database.PlayerSkins.GetByCitizenID(citizenID, model)
    if result then
        return json.decode(result)
    end
end
