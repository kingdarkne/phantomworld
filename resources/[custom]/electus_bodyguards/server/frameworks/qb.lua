if Config.framework ~= "qb" then return end

QBCore = exports['qb-core']:GetCoreObject() or exports.qbx_core:GetCoreObject()

function GetPlayer(source)
    local player = QBCore.Functions.GetPlayer(source)
    return player
end

function GetPlayerIdentifier(player)
    if(player) then
        return player.PlayerData.citizenid
    end
end

function RemoveMoney(player, amount)
    local bankMoney = player.Functions.GetMoney("bank")
    local cashMoney = player.Functions.GetMoney("cash")

    if(bankMoney >= amount) then
        player.Functions.RemoveMoney("bank", amount)
        return true
    elseif(cashMoney >= amount) then
        player.Functions.RemoveMoney("cash", amount)
        return true
    else
        return false
    end
end

function AddBankMoney(player, amount)
    player.Functions.AddMoney("bank", amount)
end

function AddCashMoney(player, amount)
    player.Functions.AddMoney("cash", amount)
end

function RemoveCashMoney(player, amount)
    player.Functions.RemoveMoney("cash", amount)
end

function RemoveBankMoney(player, amount)
    player.Functions.RemoveMoney("bank", amount)
end

function GetBankMoney(player)
    return player.Functions.GetMoney("bank")
end

function GetCashMoney(player)
    return player.Functions.GetMoney("cash")
end

function GetIdentifierName(identifier)
    local result = MySQL.Sync.fetchAll("SELECT * FROM players WHERE citizenid = @citizenid", {
        ['@citizenid'] = identifier
    })
    if(result[1]) then
        return result[1].name
    end
end