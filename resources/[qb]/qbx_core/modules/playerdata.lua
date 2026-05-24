if IsDuplicityVersion() then return end

QBX = {} -- luacheck: ignore
-- Do not call exports here: this file loads in other resources before qbx_core may have registered GetPlayerData.
QBX.PlayerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ---@diagnostic disable-next-line: missing-fields
    QBX.PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(value)
    QBX.PlayerData = value
end)
