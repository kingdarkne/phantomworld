local vehData = {}

Citizen.CreateThread(function()
    MySQL.Async.fetchAll("SELECT * FROM kaves_mechanics",{}, function(result)
        for plate, data in pairs(result) do
            vehData[data.plate] = json.decode(data.data)
        end
    end)
    if Config.Framework == "esx" then
        local func = function()
            for mName,mData in pairs(Config.Locations) do
                if mData.job ~= "none" then
                    exports['esx_addonaccount']:AddSharedAccount(('society_%s'):format(mData.job), mName, 0)
                    TriggerEvent('esx_society:registerSociety', mData.job, mData.job, ('society_%s'):format(mData.job),('society_%s'):format(mData.job), ('society_%s'):format(mData.job), {type = 'private'})
                end
            end
        end
        pcall(func)
    end
end)

addElement = function(section, data)
    if not vehData[data.plate] then
        vehData[data.plate] = {}
    end

    if section == "fitment" then
        vehData[data.plate][section] = data.fitment
    elseif data.component.mod == "Stock" then
        vehData[data.plate][section] = nil
    else
        vehData[data.plate][section] = data.component.mod
    end

    print(vehData[data.plate][section])

    MySQL.Async.fetchAll("SELECT * FROM kaves_mechanics WHERE plate = @plate", {
        ["@plate"] = data.plate
    }, function(output)
        if #output > 0 then
            MySQL.Async.execute("UPDATE kaves_mechanics SET data = @data WHERE plate = @plate",{
                ["@plate"] = data.plate,
                ["@data"] = json.encode(vehData[data.plate]),
            })
        else
            MySQL.Async.execute("INSERT INTO kaves_mechanics (plate, data) VALUES (@plate, @data)",{
                ["@plate"] = data.plate,
                ["@data"] = json.encode(vehData[data.plate]),
            })
        end
    end)

    return TriggerClientEvent("kaves_mechanic:client:updateVehData", -1, vehData)
end

RegisterServerEvent("kaves_mechanic:server:syncFitment", function(vehicleId, fitmentData)
    TriggerClientEvent("kaves_mechanic:client:syncFitment", -1, vehicleId, fitmentData)
end)

RegisterServerEvent("kaves_mechanic:server:useNitro", function(vehicleId)
    TriggerClientEvent("kaves_mechanic:client:useNitro", -1, vehicleId)
end)

RegisterServerEvent("kaves_mechanic:server:addElement", addElement)

Citizen.CreateThread(function()
    while Framework == nil do
        Citizen.Wait(100)
    end
    if Config.Framework == "esx" then

        Framework.RegisterServerCallback("kaves_mechanic:server:buyComponent", function(source, cb, data)
            local xPlayer = GetPlayer(source)

            if not xPlayer then
                return
            end

            local currentMechanic = Config.Locations[data.currentMechanic]
            if currentMechanic and currentMechanic.enableSociety then
                local societyMoney = exports['esx_addonaccount']:GetSharedAccount(('society_%s'):format(currentMechanic.job))
                if societyMoney then
                    if societyMoney.money >= data.price then
                        societyMoney.removeMoney(data.price)
                        return cb({status = true})
                    end
                end
            else
                local pMoney = GetMoney(source)
                if pMoney >= data.price then
                    RemoveMoney(source, data.price)
                    return cb({status = true})
                end
            end

            Notification(Config.Locale["dont_have_money"])
            return cb({status = false})
        end)

        Framework.RegisterServerCallback("kaves_mechanic:server:getVehData", function(source, cb)
            cb(vehData)
        end)


    elseif Config.Framework == "qbcore" then

        Framework.Functions.CreateCallback('kaves_mechanic:server:buyComponent', function(source, cb, data)
            local xPlayer = GetPlayer(source)

            if not xPlayer then
                return
            end

            local currentMechanic = Config.Locations[data.currentMechanic]
            if currentMechanic and currentMechanic.enableSociety then
                local societyMoney = exports['qb-management']:RemoveMoney(currentMechanic.job, data.price)
                if societyMoney then
                    return cb({status = true})
                end
            else
                local pMoney = GetMoney(source)
                if pMoney >= data.price then
                    RemoveMoney(source, data.price)
                    return cb({status = true})
                end
            end

            Notification(Config.Locale["dont_have_money"])
            return cb({status = false})
        end)

        Framework.Functions.CreateCallback('kaves_mechanic:server:getVehData', function(source, cb)
            cb(vehData)
        end)

    end
end)






