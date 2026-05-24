function AddInventoryItem(src, item, count)
    if(Config.inventory == "esx") then
        local xPlayer = ESX.GetPlayerFromId(src)
        xPlayer.addInventoryItem(item, count)
    elseif(Config.inventory == "qb") then
        player.Functions.AddItem(item, count)
    elseif(Config.inventory == "core") then
        exports.core_inventory:addItem(src, item, count)
    elseif(Config.inventory == "qs") then
        exports['qs-inventory']:AddItem(src, item, count)
    elseif(Config.inventory == "tgiann") then
        exports["tgiann-inventory"]:AddItem(src, item, count)
    elseif(Config.inventory == "ox_inventory") then
        exports.ox_inventory:AddItem(src, item, count)
    elseif(Config.inventory =="qb-inventory") then
        exports['qb-inventory']:AddItem(src, item, count)
    elseif(Config.inventory == "codem") then
        exports['codem-inventory']:AddItem(src, item, count)
    end
end

function RemoveInventoryItem(src, item, count)
    if(Config.inventory == "esx") then
        local xPlayer = ESX.GetPlayerFromId(src)

        xPlayer.removeInventoryItem(item, count)
    elseif(Config.inventory == "qb") then
        local player = QBCore.Functions.GetPlayer(source)

        player.Functions.RemoveItem(item, count)
    elseif(Config.inventory == "core") then
        exports.core_inventory:removeItem(src, item, count)
    elseif(Config.inventory == "qs") then
        exports['qs-inventory']:RemoveItem(src, item, count)
    elseif(Config.inventory == "tgiann") then
        exports["tgiann-inventory"]:RemoveItem(src, item, count)
    elseif(Config.inventory == "ox_inventory") then
        exports.ox_inventory:RemoveItem(src, item, count)
    elseif(Config.inventory =="qb-inventory") then
        exports['qb-inventory']:RemoveItem(src, item, count)
    elseif(Config.inventory == "codem") then
        exports['codem-inventory']:RemoveItem(src, item, count)
    end
end

function GetInventoryCount(src, item)
    if(Config.inventory == "esx") then
        local xPlayer = ESX.GetPlayerFromId(src)

        return xPlayer.getInventoryItem(item).count
    elseif(Config.inventory == "qb") then
        local player = QBCore.Functions.GetPlayer(source)

        return player.Functions.GetItemByName(item).amount
    elseif(Config.inventory == "core") then
        return exports.core_inventory:getItemCount(src, item)
    elseif(Config.inventory == "qs") then
        return exports['qs-inventory']:GetItemTotalAmount(src, item)
    elseif(Config.inventory == "tgiann") then
        return exports["tgiann-inventory"]:GetItemCount(src, item)
    elseif(Config.inventory == "ox_inventory") then
        return exports.ox_inventory:GetItemCount(src, item)
    elseif(Config.inventory =="qb-inventory") then
        return exports['qb-inventory']:GetItemCount(src, item)
    elseif(Config.inventory == "codem") then
        return exports['codem-inventory']:GetItemsTotalAmount(src, item)
    end
end

function GetTrunkInventory(src)
    -- todo


end