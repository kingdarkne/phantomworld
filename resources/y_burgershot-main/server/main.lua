local sharedConfig = require 'config.shared'
lib.versionCheck('TonybynMp4/y_burgershot')

local function getItemCount(source, itemName)
    local count = exports.ox_inventory:Search(source, 'count', itemName)
    return count or 0
end

local function hasIngredients(source, recipe, recipeType)
    local Recipe = sharedConfig.recipes[recipeType][recipe]
    if not Recipe then
        lib.print.warn("missing recipe or wrong recipeType?", recipeType, recipe)
        return false
    end
    for k, v in pairs(Recipe.ingredients) do
        local count = getItemCount(source, v.item)
        if count < (Recipe.ingredients[k].amount or 0) then
            return false
        end
    end
    return true
end

local function notify(source, msg, type, length)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'BurgerShot',
        description = msg,
        type = (type == 'primary' and 'inform') or type or 'inform',
        duration = length or 5000,
    })
end

lib.callback.register('y_burgershot:server:hasIngredients', hasIngredients)

RegisterNetEvent('y_burgershot:server:CraftMeal', function(recipe, recipeType)
    local source = source
    local Recipe = sharedConfig.recipes[recipeType][recipe]
    if not Recipe then return end

    if not hasIngredients(source, recipe, recipeType) then
        return notify(source, locale('error.missing_ingredients'), 'error')
    end

    for _, v in pairs(Recipe.ingredients) do
        exports.ox_inventory:RemoveItem(source, v.item, v.amount)
    end

    -- murdermeal: qb-inventory has no container items; give as simple item
    if recipe == 'murdermeal' then
        local ok = exports.ox_inventory:AddItem(source, 'murdermeal', 1)
        if ok ~= true then
            return notify(source, locale("error.something_went_wrong"), 'error')
        end
        return notify(source, locale('success.crafted', Recipe.label), 'success')
    end

    local ok = exports.ox_inventory:AddItem(source, recipe, 1)
    if ok ~= true then
        notify(source, locale("error.something_went_wrong"), 'error')
        return
    end
    notify(source, locale('success.crafted', Recipe.label), 'success')
end)

local stashes = {
    { id = 'burgershot_tray',     label = locale('info.tray'),    slots = 5,   weight = 10000 },
    { id = 'burgershot_hotstorage', label = locale('info.storage'), slots = 50,  weight = 75000 },
    { id = 'burgershot_storage',  label = locale('info.storage'), slots = 20,  weight = 100000 },
}

exports('GetStashConfig', function()
    return stashes
end)

CreateThread(function()
    if GetResourceState('ox_inventory') ~= 'started' then return end
    for _, stash in ipairs(stashes) do
        local slots = tonumber(stash.slots) or 20
        local maxWeight = tonumber(stash.weight or stash.maxWeight) or 100000
        pcall(function()
            exports.ox_inventory:RegisterStash(stash.id, stash.label, slots, maxWeight)
        end)
    end
end)
