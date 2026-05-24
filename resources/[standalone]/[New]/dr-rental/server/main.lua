RegisterNetEvent('dr-rental:sv:rentVehicle', function(data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid

    -- Membership hook: restrict certain rental models to specific tiers
    if GetResourceState('dr-membership') == 'started' then
        local ok = exports['dr-membership']:HasVehicleAccess(src, data.carName)
        if not ok then
            TriggerClientEvent('ox_lib:notify', src, { description = 'You need a higher membership tier to rent this vehicle.', type = 'error' })
            return
        end
    end

    if data.payType == "cash" then
        if Player.Functions.GetMoney("cash") >= data.carPrice then
            Player.Functions.RemoveMoney('cash', data.carPrice, 'cash transfer')
            TriggerClientEvent('dr-rental:cl:spawnVehicle', src, data.carName, data.carDay)
            TriggerClientEvent('ox_lib:notify', src, { description = 'Purchase transaction successful', type = 'success' })
        else
            TriggerClientEvent('ox_lib:notify', src, { description = "You don't have enough funds", type = 'error' })

        end
    else        
        if Player.PlayerData.money.bank >= data.carPrice then
            Player.Functions.RemoveMoney("bank", data.carPrice)
            TriggerClientEvent('dr-rental:cl:spawnVehicle', src, data.carName, data.carDay)
            TriggerClientEvent('ox_lib:notify', src, { description = 'Purchase transaction successful', type = 'success' })
        else
            TriggerClientEvent('ox_lib:notify', src, { description = "You don't have enough funds", type = 'error' })
        end
    end

end)

RegisterNetEvent('dr-rental:sv:updatesql', function(plate,vehicle,time)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local timeinday = time * 86400
    local endtime = tonumber(os.time() + timeinday)
    local timeTable = os.date('*t', endtime)
    MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.license,
        cid,
        vehicle,
        GetHashKey(vehicle),
        '{}',
        plate,
        'apartments',
        0
    })
    MySQL.insert('INSERT INTO rentvehs (citizenid, vehicle, plate, time) VALUES (?, ?, ?, ?)', {cid, vehicle, plate, endtime})
    TriggerClientEvent('ox_lib:notify', src, { description = ("You successfully rented this car until %d / %d / %d"):format(timeTable['day'], timeTable['month'], timeTable['year']), type = 'success', duration = 10000 })
end)

RegisterNetEvent('dr-rental:sv:checktime', function()
    local sqlresult = MySQL.Sync.fetchAll('SELECT citizenid, vehicle, plate, time FROM rentvehs', {})
    local currentTime = os.time()

    for _, row in pairs(sqlresult) do
        local citizenid = tonumber(row.citizenid)
        local timeInDB = tonumber(row.time)

        if currentTime > timeInDB then
            MySQL.Sync.execute('DELETE FROM rentvehs WHERE citizenid = ? AND vehicle = ? AND plate = ?', {row.citizenid, row.vehicle, row.plate})
            MySQL.Sync.execute('DELETE FROM player_vehicles WHERE citizenid = ? AND vehicle = ? AND plate = ?', {row.citizenid, row.vehicle, row.plate})
        end
    end
end)