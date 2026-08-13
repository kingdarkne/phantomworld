-- Custom GTA-Online style weapon wheel (TAB) — replaces ox/native wheel

local isOpen = false
local currentWeapons = {}
local selectedWeapon = nil

local function normName(name)
    return string.lower(tostring(name or ''))
end

local function isWeaponItem(item)
    if type(item) ~= 'table' or type(item.name) ~= 'string' then return false end
    local n = item.name
    if n:sub(1, 7):upper() == 'WEAPON_' then return true end
    if item.metadata and (item.metadata.weapon or item.metadata.ammo ~= nil) then
        return n:upper():find('WEAPON_', 1, true) ~= nil
    end
    return false
end

-- Get weapons from ox_inventory (slot map — use pairs, not ipairs)
local function GetInventoryWeapons()
    local weapons = {}
    local seen = {}

    if Config.Integration.useOxInventory and GetResourceState('ox_inventory') == 'started' then
        local ok, inventory = pcall(function()
            return exports.ox_inventory:GetPlayerItems()
        end)
        if ok and inventory then
            for _, item in pairs(inventory) do
                if isWeaponItem(item) then
                    local key = normName(item.name)
                    if not seen[key] then
                        seen[key] = true
                        weapons[#weapons + 1] = {
                            name = item.name,
                            label = item.label or item.name,
                            slot = item.slot,
                            ammo = item.metadata and item.metadata.ammo or 0,
                            components = item.metadata and item.metadata.components or {},
                            tint = item.metadata and item.metadata.tint or 0,
                        }
                    end
                end
            end
        end
    end

    return weapons
end

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
            local wname = normName(weapon.name)
            for _, weaponName in ipairs(category.weapons) do
                if wname == normName(weaponName) then
                    grouped[category.name].weapons[#grouped[category.name].weapons + 1] = weapon
                    break
                end
            end
        end
    end

    -- Bucket uncategorized weapons
    local known = {}
    for _, category in ipairs(Config.Categories) do
        for _, weaponName in ipairs(category.weapons) do
            known[normName(weaponName)] = true
        end
    end
    local other = {}
    for _, weapon in ipairs(weapons) do
        if not known[normName(weapon.name)] then
            other[#other + 1] = weapon
        end
    end
    if #other > 0 then
        grouped['Other'] = {
            name = 'Other',
            icon = 'other',
            color = '#AAAAAA',
            weapons = other,
        }
    end

    return grouped
end

local function disableNativeWheelThisFrame()
    if not Config.BlockNativeWheel then return end
    BlockWeaponWheelThisFrame()
    DisableControlAction(0, 37, true) -- TAB / weapon wheel
    DisableControlAction(0, 157, true) -- weapon select 1
    DisableControlAction(0, 158, true)
    DisableControlAction(0, 159, true)
    DisableControlAction(0, 160, true)
    DisableControlAction(0, 161, true)
    DisableControlAction(0, 162, true)
    DisableControlAction(0, 163, true)
    DisableControlAction(0, 164, true)
    DisableControlAction(0, 165, true)
    HideHudComponentThisFrame(19) -- weapon wheel
end

local function OpenWeaponWheel()
    if isOpen or not Config.Enabled then return end
    if IsPauseMenuActive() or IsNuiFocused() then return end

    isOpen = true
    selectedWeapon = nil

    local weapons = GetInventoryWeapons()
    currentWeapons = GroupWeaponsByCategory(weapons)

    PlaySoundFrontend(-1, Config.Sounds.open, 'HUD_AMMO_SHOP_SOUNDSET', true)

    SendNUIMessage({
        action = 'open',
        categories = currentWeapons,
        config = Config.UI,
    })

    SetNuiFocus(true, true)
end

local function CloseWeaponWheel()
    if not isOpen then return end
    isOpen = false

    PlaySoundFrontend(-1, Config.Sounds.close, 'HUD_AMMO_SHOP_SOUNDSET', true)

    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)

    if selectedWeapon and Config.Integration.autoEquip then
        EquipWeapon(selectedWeapon)
    end
end

function EquipWeapon(weaponData)
    if not weaponData or not weaponData.name then return end

    if Config.Integration.useOxInventory and GetResourceState('ox_inventory') == 'started' then
        -- Prefer slot from wheel payload
        if weaponData.slot then
            pcall(function()
                exports.ox_inventory:useItem(weaponData.slot)
            end)
            PlaySoundFrontend(-1, Config.Sounds.select, 'HUD_AMMO_SHOP_SOUNDSET', true)
            return
        end

        local ok, inventory = pcall(function()
            return exports.ox_inventory:GetPlayerItems()
        end)
        if ok and inventory then
            local target = normName(weaponData.name)
            for _, item in pairs(inventory) do
                if type(item) == 'table' and normName(item.name) == target and item.slot then
                    pcall(function()
                        exports.ox_inventory:useItem(item.slot)
                    end)
                    PlaySoundFrontend(-1, Config.Sounds.select, 'HUD_AMMO_SHOP_SOUNDSET', true)
                    return
                end
            end
        end
    end

    local ped = PlayerPedId()
    local weaponHash = joaat(weaponData.name)
    if HasPedGotWeapon(ped, weaponHash, false) then
        SetCurrentPedWeapon(ped, weaponHash, true)
    end
    PlaySoundFrontend(-1, Config.Sounds.select, 'HUD_AMMO_SHOP_SOUNDSET', true)
end

-- Always block native wheel; open custom on TAB
CreateThread(function()
    while true do
        if Config.Enabled then
            disableNativeWheelThisFrame()

            if IsDisabledControlJustPressed(0, Config.OpenKey) then
                if isOpen then
                    CloseWeaponWheel()
                else
                    OpenWeaponWheel()
                end
            end

            if isOpen then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterNUICallback('selectWeapon', function(data, cb)
    selectedWeapon = data and data.weapon or nil
    PlaySoundFrontend(-1, Config.Sounds.select, 'HUD_AMMO_SHOP_SOUNDSET', true)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    CloseWeaponWheel()
    cb({ ok = true })
end)

RegisterNUICallback('hoverWeapon', function(_, cb)
    cb({ ok = true })
end)

exports('OpenWeaponWheel', OpenWeaponWheel)
exports('CloseWeaponWheel', CloseWeaponWheel)
exports('ToggleWeaponWheel', function()
    if isOpen then CloseWeaponWheel() else OpenWeaponWheel() end
end)

-- Command only (no RegisterKeyMapping on TAB — that would double-fire with the
-- control loop below and instantly open+close the wheel).
RegisterCommand('weaponwheel', function()
    if isOpen then CloseWeaponWheel() else OpenWeaponWheel() end
end, false)

CreateThread(function()
    Wait(2000)
    -- Force ox_inventory off the native wheel so TAB is ours
    if GetResourceState('ox_inventory') == 'started' then
        pcall(function() exports.ox_inventory:weaponWheel(false) end)
        pcall(function() exports.ox_inventory:Weaponsyncdisable(true) end)
    end
    print('^2[GTA Weapon Wheel]^7 Custom wheel active — press TAB (native GTA/ox wheel disabled)')
end)

-- Re-assert after ox_inventory restarts
AddEventHandler('onClientResourceStart', function(res)
    if res ~= 'ox_inventory' then return end
    CreateThread(function()
        Wait(1500)
        pcall(function() exports.ox_inventory:weaponWheel(false) end)
        pcall(function() exports.ox_inventory:Weaponsyncdisable(true) end)
    end)
end)
