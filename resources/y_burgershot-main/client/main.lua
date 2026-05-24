local onDuty = false
local config = require 'config.client'
local sharedConfig = require 'config.shared'

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)

local function getDescription(ingredients)
    local desc = ""
    for _, v in pairs(ingredients) do
        local label = (config.ingredientsLabels and config.ingredientsLabels[v.item]) or v.item
        desc = desc .. (label or v.item) .. " x" .. (v.amount or 1) .. " | "
    end
    return string.sub(desc, 1, -4)
end

local function notify(msg, type, length)
    lib.notify({
        title = 'BurgerShot',
        description = msg,
        type = (type == 'primary' and 'inform') or type or 'inform',
        duration = length or 5000,
    })
end

local function openStash(stashId)
    exports.ox_inventory:openInventory('stash', stashId)
end

local function craftPrep(recipe)
    if not onDuty then
        return notify(locale('error.notOnDuty'), "error")
    end

    local HasIngredients = lib.callback.await('y_burgershot:server:hasIngredients', false, recipe, "prep")
    if not HasIngredients then
        return notify(locale("error.missing_ingredients"), 'error', 7500)
    end

    if lib.progressBar({
        duration = 4000,
        label = locale('progress.cooking'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, combat = true, move = true },
        anim = { dict = 'amb@prop_human_bbq@male@base', clip = 'base' },
        prop = { model = `prop_cs_fork`, bone = 28422, pos = vec3(-0.005, 0.00, 0.00), rot = vec3(175.0, 160.0, 0.0) },
    }) then
        TriggerServerEvent('y_burgershot:server:CraftMeal', recipe, "prep")
    else
        notify(locale('error.cancel'), 'error', 7500)
    end
end

local function craftDrink(recipe)
    if not onDuty then
        return notify(locale('error.notOnDuty'), "error")
    end

    local HasIngredients = lib.callback.await('y_burgershot:server:hasIngredients', false, recipe, "drinks")
    if not HasIngredients then
        return notify(locale("error.missing_ingredients"), 'error', 7500)
    end

    if lib.progressBar({
        duration = 4000,
        label = locale('progress.making_drink'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, combat = true, move = true },
    }) then
        TriggerServerEvent('y_burgershot:server:CraftMeal', recipe, "drinks")
    else
        notify(locale('error.cancel'), 'error', 7500)
    end
end

local function craftMeal(recipe)
    if not onDuty then
        return notify(locale('error.notOnDuty'), "error")
    end

    local HasIngredients = lib.callback.await('y_burgershot:server:hasIngredients', false, recipe, 'burgers')
    if not HasIngredients then
        return notify(locale("error.missing_ingredients"), 'error', 7500)
    end

    if lib.progressBar({
        duration = 4000,
        label = locale('progress.making_burger'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, combat = true, move = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
    }) then
        TriggerServerEvent('y_burgershot:server:CraftMeal', recipe, 'burgers')
    else
        notify(locale('error.cancel'), 'error', 7500)
    end
end

local function openDrinksMenu()
    local Recipes = sharedConfig.recipes.drinks
    local options = {}
    for k, v in pairs(Recipes) do
        options[#options + 1] = {
            title = v.label,
            description = getDescription(v.ingredients),
            icon = 'utensils',
            onSelect = function() craftDrink(k) end,
        }
    end
    lib.registerContext({ id = 'BurgerShot_CraftMenu', title = locale('menus.drinks_title'), options = options })
    lib.showContext('BurgerShot_CraftMenu')
end

local function openBurgerMenu()
    local Recipes = sharedConfig.recipes.burgers
    local options = {}
    for k, v in pairs(Recipes) do
        options[#options + 1] = {
            title = v.label,
            description = getDescription(v.ingredients),
            icon = 'utensils',
            onSelect = function() craftMeal(k) end,
        }
    end
    lib.registerContext({ id = 'BurgerShot_CraftMenu', title = locale('menus.burger_title'), options = options })
    lib.showContext('BurgerShot_CraftMenu')
end

-- qb-target: AddBoxZone(name, center, length, width, zoneOpts, targetOpts)
local function addBoxZone(name, coords, size, rotation, distance, optionList)
    local c = type(coords) == 'vector3' and coords or vec3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
    local s = type(size) == 'vector3' and size or vec3(size.x or size[1] or 1, size.y or size[2] or 1, size.z or size[3] or 1)

    local opts = {}
    for _, o in ipairs(optionList) do
        opts[#opts + 1] = {
            icon = o.icon or "fas fa-circle",
            label = o.label,
            groups = { burgershot = 0 },
            onSelect = function()
                o.action()
            end
        }
    end

    exports.ox_target:addBoxZone({
        name = name,
        coords = c,
        size = s,
        rotation = rotation or 0.0,
        debug = config.zoneDebug,
        options = opts,
        distance = distance or 2.5,
    })
end

CreateThread(function()
    addBoxZone("BurgerShot_Duty", sharedConfig.coords.duty.coords, sharedConfig.coords.duty.size, sharedConfig.coords.duty.rotation, 3.0, {
        { icon = "fas fa-clipboard", label = locale('info.duty'), action = function()
            onDuty = not onDuty
            TriggerServerEvent("QBCore:ToggleDuty")
        end }
    })

    addBoxZone("BurgerShot_Cook", sharedConfig.coords.cook.coords, sharedConfig.coords.cook.size, sharedConfig.coords.cook.rotation, 1.5, {
        { icon = "fas fa-hamburger", label = locale('info.burger_cook'), action = function() craftPrep("steak") end }
    })

    addBoxZone("BurgerShot_Cook_2", sharedConfig.coords.cook_2.coords, sharedConfig.coords.cook_2.size, sharedConfig.coords.cook_2.rotation, 1.5, {
        { icon = "fas fa-hamburger", label = locale('info.burger_cook'), action = function() craftPrep("steak") end }
    })

    addBoxZone("BurgerShot_Fry", sharedConfig.coords.fry.coords, sharedConfig.coords.fry.size, sharedConfig.coords.fry.rotation, 1.5, {
        { icon = "fas fa-hamburger", label = locale('info.fries_cook'), action = function() craftPrep("fries") end }
    })

    addBoxZone("BurgerShot_Burgers_Craft", sharedConfig.coords.burgers.coords, sharedConfig.coords.burgers.size, sharedConfig.coords.burgers.rotation, 1.5, {
        { icon = "fas fa-utensils", label = locale('info.craft'), action = openBurgerMenu }
    })

    addBoxZone("BurgerShot_Drinks_Craft", sharedConfig.coords.drinks.coords, sharedConfig.coords.drinks.size, sharedConfig.coords.drinks.rotation, 1.5, {
        { icon = "fas fa-utensils", label = locale('info.craft'), action = openDrinksMenu }
    })

    addBoxZone("burger_tray", sharedConfig.coords.tray.coords, sharedConfig.coords.tray.size, sharedConfig.coords.tray.rotation, 1.5, {
        { icon = "fas fa-clipboard", label = locale('info.tray'), action = function() openStash('burgershot_tray') end }
    })

    addBoxZone("burgershot_hotstorage", sharedConfig.coords.hotstorage.coords, sharedConfig.coords.hotstorage.size, sharedConfig.coords.hotstorage.rotation, 1.5, {
        { icon = "fas fa-box", label = locale('info.storage'), action = function() openStash('burgershot_hotstorage') end }
    })

    addBoxZone("burgershot_storage", sharedConfig.coords.storage.coords, sharedConfig.coords.storage.size, sharedConfig.coords.storage.rotation, 2.0, {
        { icon = "fas fa-box", label = locale('info.storage'), action = function() openStash('burgershot_storage') end }
    })
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local pd = exports.qbx_core:GetPlayerData()
    onDuty = pd and pd.job and pd.job.onduty or false
end)
