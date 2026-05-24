-- Phantom Core - Vehicle Tuning System
-- High-quality vehicle tuning with performance and visual upgrades

local tuningCategories = {
    { id = 'engine', name = 'Engine', icon = '⚙️', modType = 11 },
    { id = 'brakes', name = 'Brakes', icon = '🛑', modType = 12 },
    { id = 'transmission', name = 'Transmission', icon = '⚡', modType = 13 },
    { id = 'suspension', name = 'Suspension', icon = '🔧', modType = 15 },
    { id = 'armor', name = 'Armor', icon = '🛡️', modType = 16 },
    { id = 'turbo', name = 'Turbo', icon = '💨', modType = 18 },
    { id = 'wheels', name = 'Wheels', icon = '🛞', modType = 23 },
    { id = 'spoiler', name = 'Spoiler', icon = '🏎️', modType = 0 },
    { id = 'bumper_f', name = 'Front Bumper', icon = '🚗', modType = 1 },
    { id = 'bumper_r', name = 'Rear Bumper', icon = '🚗', modType = 2 },
    { id = 'skirt', name = 'Side Skirts', icon = '🚗', modType = 3 },
    { id = 'exhaust', name = 'Exhaust', icon = '💨', modType = 4 },
    { id = 'grille', name = 'Grille', icon = '🚗', modType = 6 },
    { id = 'hood', name = 'Hood', icon = '🚗', modType = 7 },
    { id = 'roof', name = 'Roof', icon = '🚗', modType = 10 },
    { id = 'livery', name = 'Livery', icon = '🎨', modType = 48 },
}

local currentVehicle = nil
local currentTuningCategory = nil

-- Open tuning menu
function OpenTuningMenu(vehicle)
    currentVehicle = vehicle
    
    if not DoesEntityExist(vehicle) then
        SendNotification({
            type = 'error',
            message = 'No vehicle nearby'
        })
        return
    end
    
    local options = {}
    
    for _, category in ipairs(tuningCategories) do
        table.insert(options, {
            label = category.name,
            description = 'Upgrade your vehicle ' .. category.name,
            icon = category.icon,
            args = { type = 'category', id = category.id, modType = category.modType }
        })
    end
    
    -- Add reset option
    table.insert(options, {
        label = 'Reset All Upgrades',
        description = 'Remove all vehicle upgrades',
        icon = '🔄',
        args = { type = 'reset' }
    })
    
    ShowMenu({
        title = 'Vehicle Tuning',
        options = options
    })
end

-- Open tuning category menu
function OpenTuningCategory(categoryId, modType)
    currentTuningCategory = categoryId
    local options = {}
    
    local vehicle = currentVehicle
    local currentMod = GetVehicleMod(vehicle, modType)
    local maxMods = GetNumVehicleMods(vehicle, modType)
    
    -- Show current level
    if maxMods > 0 then
        table.insert(options, {
            label = 'Current Level: ' .. (currentMod + 1) .. '/' .. maxMods,
            description = 'Your current upgrade level',
            icon = '📊',
            disabled = true
        })
    end
    
    -- Add upgrade options
    for i = 0, maxMods - 1 do
        local price = GetUpgradePrice(categoryId, i)
        local isInstalled = (i == currentMod)
        
        table.insert(options, {
            label = 'Level ' .. (i + 1),
            description = isInstalled and 'Installed' or ('Price: ' .. FormatMoney(price)),
            icon = isInstalled and '✅' or '⬆️',
            disabled = isInstalled,
            args = { type = 'upgrade', level = i, price = price, modType = modType }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to tuning menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = tuningCategories[categoryId].name,
        options = options
    })
end

-- Get upgrade price
function GetUpgradePrice(categoryId, level)
    local prices = Config.Vehicles.Tuning.Prices[categoryId]
    if prices then
        return prices[level + 1] or prices[#prices]
    end
    return 5000
end

-- Apply upgrade
function ApplyUpgrade(modType, level, price)
    local vehicle = currentVehicle
    
    -- Check if player has enough money
    -- This would integrate with the economy system
    
    ShowProgressBar({
        duration = 2000,
        label = 'Installing upgrade...',
        canCancel = false
    })
    
    -- Apply the upgrade
    SetVehicleMod(vehicle, modType, level, false)
    
    -- For turbo
    if modType == 18 then
        ToggleVehicleMod(vehicle, 18, true)
    end
    
    SendNotification({
        type = 'vehicle',
        message = 'Upgrade installed successfully'
    })
    
    -- Deduct money
    -- This would integrate with the banking system
    
    CloseMenu()
end

-- Reset all upgrades
function ResetUpgrades()
    local vehicle = currentVehicle
    
    ShowConfirmDialog({
        title = 'Reset Upgrades',
        message = 'Are you sure you want to remove all upgrades?',
        confirmText = 'Yes',
        cancelText = 'No',
        callback = function(values, confirmed)
            if confirmed then
                ShowProgressBar({
                    duration = 2000,
                    label = 'Removing upgrades...',
                    canCancel = false
                })
                
                -- Reset all mods
                for _, category in ipairs(tuningCategories) do
                    if category.modType ~= 18 then -- Skip turbo
                        SetVehicleMod(vehicle, category.modType, -1, false)
                    else
                        ToggleVehicleMod(vehicle, 18, false)
                    end
                end
                
                SendNotification({
                    type = 'vehicle',
                    message = 'All upgrades removed'
                })
            end
        end
    })
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'category' then
        OpenTuningCategory(data.args.id, data.args.modType)
    elseif data.args.type == 'upgrade' then
        ApplyUpgrade(data.args.modType, data.args.level, data.args.price)
    elseif data.args.type == 'reset' then
        ResetUpgrades()
    elseif data.args.type == 'back' then
        OpenTuningMenu(currentVehicle)
    end
    cb({})
end)

-- Command to open tuning menu
RegisterCommand('tuning', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        OpenTuningMenu(vehicle)
    else
        SendNotification({
            type = 'error',
            message = 'You must be in a vehicle'
        })
    end
end)

-- Export functions
exports('OpenTuningMenu', OpenTuningMenu)
exports('ApplyUpgrade', ApplyUpgrade)

DebugPrint('Vehicle tuning system loaded')
