local QBCore = exports['qbx_core']:GetCoreObject()

-- Награды за добычу
local rewards = {
    deer_carcass = {
        items = {
            {name = "meat", amount = 4},
            {name = "leather", amount = 2}
        },
        money = 25
    },
    rabbit_carcass = {
        items = {
            {name = "meat", amount = 1},
            {name = "leather", amount = 1}
        },
        money = 15
    },
    mtlion_carcass = {
        items = {
            {name = "meat", amount = 3},
            {name = "leather", amount = 3}
        },
        money = 50
    },
    bird_carcass = {
        items = {
            {name = "meat", amount = 1},
            {name = "feathers", amount = 2}
        },
        money = 5
    }
}

-- Weapon license check
lib.callback.register('hunting:checkWeaponLicense', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local licenseTable = Player.PlayerData.metadata['licences']
    return licenseTable and licenseTable.weapon or false
end)

-- Обработчик события сбора добычи
RegisterNetEvent('hunting:harvestAnimal')
AddEventHandler('hunting:harvestAnimal', function(rewardType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local reward = rewards[rewardType]
    if not reward then return end
    
    -- Give items via ox_inventory
    for _, item in pairs(reward.items) do
        exports.ox_inventory:AddItem(src, item.name, item.amount)
    end
    
    -- Give money
    Player.Functions.AddMoney('cash', reward.money)
    
    TriggerClientEvent('ox_lib:notify', src, { title = 'Hunting', description = 'You received loot and $' .. reward.money, type = 'success' })
end)