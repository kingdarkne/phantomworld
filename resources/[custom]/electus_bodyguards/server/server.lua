RegisterNetEvent("electus_bodyguards:insertBodyguard", function(price, slot, model, weapon, days, components)
    local src = source
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)
    local removedMoney = RemoveMoney(player, price)

    if(removedMoney) then
        local time = os.time()
        MySQL.insert.await([[
            INSERT INTO electus_bodyguards (`identifier`, `slot`, `model`, `weapon`, `time`, `days`, `isDead`, `inService`, `isRecruit`, `isBackup`, `components`) 
            VALUES (@identifier, @slot, @model, @weapon, @time, @days, @isDead, @inService, @isRecruit, @isBackup, @components)
            ]], {
            ['@identifier'] = identifier,
            ['@slot'] = slot,
            ['@model'] = model,
            ['@weapon'] = weapon,
            ['@time'] = time,
            ['@days'] = days,
            ['@isDead'] = 0,
            ['@inService'] = 1,
            ['@isRecruit'] = 0,
            ['@isBackup'] = 0,
            ["@components"] = nil,
        })
        TriggerClientEvent("electus_bodyguards:insertBodyguard", src, {slot=slot, model=model, weapon=weapon, time=os.time()-time, days=days, isDead=0, inService=1, isBackup = 0, isRecruit = 0, components = components})
    else
        Notify(src, L("notEnoughMoney"), "error") -- not enough money
    end
end)

RegisterNetEvent("electus_bodyguards:insertBackupBodyguard", function(slot, model, weapon, days, components)
    local src = source
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)
    local time = os.time()

    MySQL.insert.await("INSERT INTO electus_bodyguards (`identifier`, `slot`, `model`, `weapon`, `time`, `days`, `isDead`, `inService`, `isRecruit`, `isBackup`, `components`) VALUES (@identifier, @slot, @model, @weapon, @time, @days, @isDead, @inService, @isRecruit, @isBackup, @components)", {
        ['@identifier'] = identifier,
        ['@slot'] = slot,
        ['@model'] = model,
        ['@weapon'] = weapon,
        ['@time'] = time,
        ['@days'] = days,
        ['@isDead'] = 0,
        ['@inService'] = 1,
        ['@isRecruit'] = 0,
        ['@isBackup'] = 1,
        ["@components"] = json.encode(components),
    })
end)

function UpdateBodyguardToDB(src, bodyguard)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)
    MySQL.update.await("UPDATE electus_bodyguards SET `isDead` = ?, `inService` = ?, `components` = ? WHERE `identifier`= ? AND `slot` = ?", {
        bodyguard.isDead,
        bodyguard.inService,
        json.encode(bodyguard.components),
        identifier,
        bodyguard.slot,
    })
end

RegisterNetEvent("electus_bodyguards:updateBodyguard", function(bodyguard)
    local src = source
    UpdateBodyguardToDB(src, bodyguard)
end)

RegisterNetEvent("electus_bodyguards:terminateContract", function(slot)
    local src = source
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)
    MySQL.update.await("DELETE FROM electus_bodyguards WHERE `slot` = ? AND `identifier` = ?", {
        slot,
        identifier,
    })
end)

lib.callback.register("electus_bodyguards:hasItem", function(src, item)
    local player = GetPlayer(src)
    local inventoryCount = GetInventoryCount(src, item)

    return inventoryCount > 0
end)


lib.callback.register("electus_bodyguards:getNbrOfEmptyBackupSlots", function(src)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)

    local bodyguards = MySQL.query.await("SELECT * FROM electus_bodyguards WHERE identifier = ? AND slot < 0", {identifier})

    return Config.maxBackups - #bodyguards
end)

lib.callback.register("electus_bodyguards:getNextBackupSlot", function(src)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)

    local bodyguards = MySQL.query.await("SELECT * FROM electus_bodyguards WHERE identifier = ? AND slot < 0", {identifier})

    for i=-1, -1*Config.maxBackups, -1 do
        local found = false
        for j=1,#bodyguards do
            if(bodyguards[j].slot == i) then
                found = true
                break
            end
        end
        if(not found) then
            return i
        end
    end
end)

lib.callback.register("electus_bodyguards:disableControlFilter", function(src, netId)
    SetEntityIgnoreRequestControlFilter(NetworkGetEntityFromNetworkId(netId), false)
end)

lib.callback.register("electus_bodyguards:getBodyguards", function(src)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)

    local bodyguards = MySQL.query.await("SELECT * FROM electus_bodyguards WHERE identifier = ?", {identifier})
    if(bodyguards[1]) then
        for i=1,#bodyguards do
            bodyguards[i].time = os.time() - bodyguards[i].time
        end
    end

    return bodyguards
end)
