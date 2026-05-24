-- GTA-Online Style Weapon Wheel - Client
-- Integrated with ox_inventory/qbx_core

local QBCore = exports['qbx_core']:GetCoreObject()
local isOpen = false
local currentWeapons = {}
local selectedCategory = nil
local selectedWeapon = nil

-- Get weapons from ox_inventory
local function GetInventoryWeapons()
    local weapons = {}
    
    if Config.Integration.useOxInventory then
        local inventory = exports.ox_inventory:GetPlayerItems()
        if inventory then
            for _, item in ipairs(inventory) do
                if item.metadata and item.metadata.weapon then
                    table.insert(weapons, {
                        name = item.name,
                        label = item.label or item.name,
                        ammo = item.metadata.ammo or 0,
                        components = item.metadata.components or {},
                        tint = item.metadata.tint or 0,
                    })
                elseif string.find(item.name, 'WEAPON_') then
                    table.insert(weapons, {
                        name = item.name,
                        label = item.label or item.name,
                        ammo = item.metadata and item.metadata.ammo or 0,
                        components = item.metadata and item.metadata.components or {},
                        tint = item.metadata and item.metadata.tint or 0,
                    })
                end
            end
        end
    end
    
    -- Also check equipped weapons
    local ped = PlayerPedId()
    for _, category in ipairs(Config.Categories) do
        for _, weaponName in ipairs(category.weapons) do
            local hash = GetHashKey(weaponName)
            if HasPedGotWeapon(ped, hash, false) then
                -- Check if already in inventory list
                local found = false
                for _, w in ipairs(weapons) do
                    if w.name == weaponName then
                        found = true
                        break
                    end
                end
                
                if not found then
                    local ammo = GetAmmoInPedWeapon(ped, hash)
                    table.insert(weapons, {
                        name = weaponName,
                        label = weaponName:gsub('weapon_', ''):upper(),
                        ammo = ammo,
                        components = {},
                        tint = 0,
                    })
                end
            end
        end
    end
    
    return weapons
end

-- Group weapons by category
local function GroupWeaponsByCategory(weapons)
    local grouped = {}
    
    for _, category in ipairs(Config.Categories) do
        grouped[category.name] = {
            name = category.name,
            icon = category.icon,
            color = category.color,
            weapons = {}
        }
        
        for _, weapon in ipairs(weapons) do
            for _, weaponName in ipairs(category.weapons) do
                if weapon.name == weaponName or weapon.name == string.lower(weaponName) then
                    table.insert(grouped[category.name].weapons, weapon)
                    break
                end
            end
        end
    end
    
    return grouped
end

-- Open weapon wheel
local function OpenWeaponWheel()
    if isOpen or not Config.Enabled then return end
    
    isOpen = true
    
    -- Get weapons from inventory
    local weapons = GetInventoryWeapons()
    currentWeapons = GroupWeaponsByCategory(weapons)
    
    -- Disable controls
    DisableControlAction(0, 37, true) -- TAB
    DisableControlAction(0, 1, true) -- Look left/right
    DisableControlAction(0, 2, true) -- Look up/down
    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 25, true) -- Aim
    
    -- Play sound
    PlaySoundFrontend(-1, Config.Sounds.open, 'HUD_AMMO_SHOP_SOUNDSET', true)
    
    -- Send to NUI
    SendNUIMessage({
        action = 'open',
        categories = currentWeapons,
        config = Config.UI,
    })
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    print('^2[GTA Weapon Wheel]^7 Weapon wheel opened')
end

-- Close weapon wheel
local function CloseWeaponWheel()
    if not isOpen then return end
    
    isOpen = false
    
    -- Play sound
    PlaySoundFrontend(-1, Config.Sounds.close, 'HUD_AMMO_SHOP_SOUNDSET', true)
    
    -- Send to NUI
    SendNUIMessage({
        action = 'close',
    })
    
    -- Release NUI focus
    SetNuiFocus(false, false)
    
    -- Equip selected weapon
    if selectedWeapon and Config.Integration.autoEquip then
        EquipWeapon(selectedWeapon)
    end
    
    print('^2[GTA Weapon Wheel]^7 Weapon wheel closed')
end

-- Equip weapon
function EquipWeapon(weaponData)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weaponData.name)
    
    if not HasPedGotWeapon(ped, weaponHash, false) then
        -- Try to use from inventory
        if Config.Integration.useOxInventory then
            local inventory = exports.ox_inventory:GetPlayerItems()
            if inventory then
                for _, item in ipairs(inventory) do
                    if item.name == weaponData.name or item.metadata and item.metadata.weapon == weaponData.name then
                        exports.ox_inventory:useItem(item.slot, nil)
                        break
                    end
                end
            end
        end
    else
        -- Just equip it
        SetCurrentPedWeapon(ped, weaponHash, true)
    end
    
    -- Play sound
    PlaySoundFrontend(-1, Config.Sounds.select, 'HUD_AMMO_SHOP_SOUNDSET', true)
    
    print('^2[GTA Weapon Wheel]^7 Equipped: ' .. weaponData.name)
end

-- Handle key press
CreateThread(function()
    while true do
        Wait(0)
        
        if Config.Enabled then
            if IsDisabledControlJustPressed(0, Config.OpenKey) then
                if isOpen then
                    CloseWeaponWheel()
                else
                    OpenWeaponWheel()
                end
            end
            
            if isOpen then
                -- Keep controls disabled
                DisableControlAction(0, 37, true)
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
            end
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('selectWeapon', function(data, cb)
    selectedWeapon = data.weapon
    PlaySoundFrontend(-1, Config.Sounds.select, 'HUD_AMMO_SHOP_SOUNDSET', true)
    cb({})
end)

RegisterNUICallback('close', function(data, cb)
    CloseWeaponWheel()
    cb({})
end)

RegisterNUICallback('hoverWeapon', function(data, cb)
    -- Play hover sound if needed
    cb({})
end)

-- Exports
exports('OpenWeaponWheel', OpenWeaponWheel)
exports('CloseWeaponWheel', CloseWeaponWheel)
exports('ToggleWeaponWheel', function()
    if isOpen then
        CloseWeaponWheel()
    else
        OpenWeaponWheel()
    end
end)

-- Command to open weapon wheel
RegisterCommand('weaponwheel', function()
    if isOpen then
        CloseWeaponWheel()
    else
        OpenWeaponWheel()
    end
end, false)

-- Key mapping
RegisterKeyMapping('weaponwheel', 'Toggle Weapon Wheel', 'keyboard', 'NUMPAD0')

-- Initialize
CreateThread(function()
    Wait(1000)
    print('^2[GTA Weapon Wheel]^7 Resource loaded - Press NUMPAD0 to open weapon wheel')
end)
