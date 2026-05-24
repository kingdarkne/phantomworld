local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent("Drones:Disconnect")
AddEventHandler('Drones:Disconnect', function(drone, drone_data, pos)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    TriggerClientEvent('Drones:DropDrone', xPlayer.source, drone, drone_data, pos)
end)

RegisterServerEvent("Drones:Back")
AddEventHandler('Drones:Back', function(drone_data)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not drone_data.singleuse then
        xPlayer.Functions.AddItem(drone_data.name, 1)
    end
end)

QBCore.Functions.CreateUseableItem("drone", function(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)

    if xPlayer.Functions.GetItemByName('drone') then
        local drone_data = Config.Drones[1]
        TriggerClientEvent("Drones:UseDrone", source, drone_data)
        xPlayer.Functions.RemoveItem('drone', 1)
        TriggerClientEvent('QBCore:Notify', source, 'Drone deployed!', 'success') 
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have a drone!', 'error') 
    end
end)

QBCore.Functions.CreateUseableItem("drone_lspd", function(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)

    if xPlayer.Functions.GetItemByName('drone_lspd') then
        local drone_data = Config.Drones[2]
        TriggerClientEvent("Drones:UseDrone", source, drone_data)
        xPlayer.Functions.RemoveItem('drone_lspd', 1)
        TriggerClientEvent('QBCore:Notify', source, 'Drone deployed!', 'success') 
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have a drone!', 'error') 
    end
end)

QBCore.Functions.CreateUseableItem("drone_nano", function(source)
    local xPlayer = QBCore.Functions.GetPlayer(source)

    if xPlayer.Functions.GetItemByName('drone_nano') then
        local drone_data = Config.Drones[3]
        TriggerClientEvent("Drones:UseDrone", source, drone_data)
        xPlayer.Functions.RemoveItem('drone_nano', 1)
        TriggerClientEvent('QBCore:Notify', source, 'Drone deployed!', 'success') 
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have a drone!', 'error') 
    end
end)