if Config.framework ~= "esx" then return end

export, ESX = pcall(function()
    return exports.es_extended:getSharedObject()
end)

if not export then
    TriggerEvent("esx:getSharedObject", function(obj)
        ESX = obj
    end)
end

function GetPlayer(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer
end

function GetPlayerIdentifier(player)
    return player.getIdentifier()
end

function RemoveMoney(player, amount)
    local bankMoney = player.getAccount("bank").money
    local cashMoney = player.getAccount("money").money

    if(bankMoney >= amount) then
        player.removeAccountMoney("bank", amount)
        return true
    elseif(cashMoney >= amount) then
        player.removeAccountMoney("money", amount)
        return true
    else
        return false
    end
end

function RemoveCashMoney(player, amount)
    player.removeAccountMoney("money", amount)
end

function RemoveBankMoney(player, amount)
    player.removeAccountMoney("bank", amount)
end

function AddCashMoney(player, amount)
    player.addAccountMoney("money", amount)
end

function AddBankMoney(player, amount)
    player.addAccountMoney("bank", amount)
end

function GetBankMoney(player)
    return player.getAccount("bank").money
end

function GetCashMoney(player)
    return player.getAccount("money").money
end

function GetIdentifierName(identifier)
    local result = MySQL.Sync.fetchAll("SELECT firstname, lastname FROM users WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    })

    if(result[1]) then
        return result[1].firstname .. " " .. result[1].lastname
    else
        return "Unknown"
    end
end