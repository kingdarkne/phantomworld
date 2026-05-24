-- Phantom Weapons - Main Client
local QBCore = exports['qbx_core']:GetCoreObject()
local weaponWheelOpen = false
local currentSlot = 1
local ammuNationBlips = {}
local weaponLockerBlips = {}

-- Initialize
CreateThread(function()
    Wait(2000)
    CreateAmmuNationBlips()
    CreateWeaponLockerBlips()
    print('^2[Phantom Weapons]^7 Client initialized')
end)

-- Create Ammu-Nation blips
function CreateAmmuNationBlips()
    for _, location in ipairs(Config.AmmuNationLocations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, 110)
        SetBlipColour(blip, 4)
        SetBlipScale(blip, 0.9)
        SetBlipAsShortRange(blip, true)
        SetBlipDisplay(blip, 4)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(location.name)
        EndTextCommandSetBlipName(blip)
        table.insert(ammuNationBlips, blip)
    end
end

-- Create Weapon Locker blips
function CreateWeaponLockerBlips()
    for _, locker in ipairs(Config.WeaponLockers) do
        local blip = AddBlipForCoord(locker.coords.x, locker.coords.y, locker.coords.z)
        SetBlipSprite(blip, 421) -- Safe icon
        SetBlipColour(blip, 3) -- Blue
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        SetBlipDisplay(blip, 4)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('🔒 ' .. locker.name)
        EndTextCommandSetBlipName(blip)
        table.insert(weaponLockerBlips, blip)
    end
end

-- Check proximity to Ammu-Nation
CreateThread(function()
    while true do
        Wait(1000)
        if not weaponWheelOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for _, location in ipairs(Config.AmmuNationLocations) do
                local dist = #(coords - location.coords)
                if dist < 15.0 then
                    DrawMarker(29, location.coords.x, location.coords.y, location.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 100, 100, 200, false, false, 2, true, nil, nil, false)

                    if dist < 2.0 then
                        Draw3DText(location.coords + vec3(0, 0, 1.0), '~r~[E]~w~ Shop Weapons\n' .. location.name, 0.35, 4)
                        if IsControlJustPressed(0, 38) then
                            OpenAmmuNation()
                        end
                    end
                end
            end

            -- Check weapon lockers
            for _, locker in ipairs(Config.WeaponLockers) do
                local dist = #(coords - locker.coords)
                if dist < 20.0 then
                    DrawMarker(43, locker.coords.x, locker.coords.y, locker.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 100, 150, 255, 100, false, false, 2, false, nil, nil, false)
                end
                if dist < 2.0 then
                    Draw3DText(locker.coords + vec3(0, 0, 1.0), '~b~[E]~w~ Weapon Locker\n' .. locker.name, 0.35, 4)
                    if IsControlJustPressed(0, 38) then
                        OpenWeaponLocker()
                    end
                end
            end
        end
    end
end)

-- Open Ammu-Nation store
function OpenAmmuNation()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAmmuNation',
        weapons = Config.WeaponPrices,
        ammo = Config.AmmoPrices,
        tints = Config.WeaponTints,
        attachments = Config.Attachments,
    })
end

-- Open Weapon Locker
function OpenWeaponLocker()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local weapons = PlayerData.items or {}
    local weaponItems = {}

    for _, item in ipairs(weapons) do
        if item and string.find(item.name, 'weapon_') then
            table.insert(weaponItems, item)
        end
    end

    local options = {}
    for _, weapon in ipairs(weaponItems) do
        table.insert(options, {
            title = weapon.label or weapon.name:gsub('weapon_', ''):upper(),
            description = 'Store in locker',
            onSelect = function()
                TriggerServerEvent('phantom_weapons:server:storeWeapon', weapon.name)
                lib.notify({ title = 'Weapon Stored', description = weapon.label, type = 'success' })
            end
        })
    end

    -- Retrieve option
    table.insert(options, {
        title = 'Retrieve Weapons',
        description = 'Get stored weapons',
        onSelect = function()
            TriggerServerEvent('phantom_weapons:server:retrieveWeapons')
        end
    })

    lib.registerContext({ id = 'weapon_locker', title = '🔫 Weapon Locker', options = options })
    lib.showContext('weapon_locker')
end

-- Disable default weapon wheel
CreateThread(function()
    while true do
        Wait(0)
        if Config.WeaponWheel.enabled then
            -- Disable default weapon selection controls (we replace it with our own NUI wheel)
            DisableControlAction(0, 37, true) -- Tab (weapon wheel)
            HideHudComponentThisFrame(19) -- Hide weapon wheel HUD
            HideHudComponentThisFrame(20) -- Hide weapon stats

            -- Disable default weapon switch keys when our wheel is enabled
            DisableControlAction(0, 157, true) -- 1 key
            DisableControlAction(0, 158, true) -- 2 key
            DisableControlAction(0, 160, true) -- 3 key
            DisableControlAction(0, 164, true) -- 4 key
            DisableControlAction(0, 165, true) -- 5 key
            DisableControlAction(0, 159, true) -- 6 key
        end
    end
end)

-- Weapon Wheel System
CreateThread(function()
    while true do
        Wait(0)
        if Config.WeaponWheel.enabled then
            -- Check if holding weapon wheel key (use IsDisabledControlPressed since we disabled it)
            if IsDisabledControlPressed(0, Config.WeaponWheel.holdKey) then
                if not weaponWheelOpen then
                    OpenWeaponWheel()
                end
                HandleWeaponWheelInput()
            elseif weaponWheelOpen then
                CloseWeaponWheel()
            end
        end
    end
end)

function OpenWeaponWheel()
    weaponWheelOpen = true

    -- Get current weapons
    local ped = PlayerPedId()
    local weapons = GetWeaponsInSlots()

    SetNuiFocus(true, false) -- Mouse focus but allow mouse movement
    SendNUIMessage({
        action = 'openWeaponWheel',
        categories = Config.WeaponWheel.categories,
        weapons = weapons,
        currentSlot = currentSlot,
    })

    -- Disable controls while wheel is open
    CreateThread(function()
        while weaponWheelOpen do
            Wait(0)
            DisableControlAction(0, 1, true) -- Look left/right
            DisableControlAction(0, 2, true) -- Look up/down
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 30, true) -- Move left/right
            DisableControlAction(0, 31, true) -- Move up/down
        end
    end)
end

function CloseWeaponWheel()
    weaponWheelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeWeaponWheel' })

    -- Equip selected weapon
    if currentSlot then
        EquipWeaponFromSlot(currentSlot)
    end
end

function HandleWeaponWheelInput()
    local ped = PlayerPedId()
    local mouseX = GetControlNormal(0, 239) - 0.5
    local mouseY = GetControlNormal(0, 240) - 0.5

    -- Calculate angle for slot selection
    local angle = math.atan2(mouseY, mouseX) * (180 / math.pi)
    angle = angle + 90
    if angle < 0 then angle = angle + 360 end

    -- Determine slot (6 slots = 60 degrees each)
    local slot = math.floor(angle / 60) + 1
    if slot > 6 then slot = 6 end
    if slot < 1 then slot = 1 end

    if slot ~= currentSlot then
        currentSlot = slot
        SendNUIMessage({ action = 'selectSlot', slot = slot })
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
end

function GetWeaponsInSlots()
    local ped = PlayerPedId()
    -- Array indexed by wheel slot (1..6): either nil or { weaponName, displayName, ammo }
    local weaponsInSlots = {}
    local PlayerData = QBCore.Functions.GetPlayerData()
    local inventory = PlayerData.items or {}
    
    -- Get all weapons from inventory
    local inventoryWeapons = {}
    for _, item in ipairs(inventory) do
        if item and item.name and string.find(item.name, 'weapon_') then
            inventoryWeapons[item.name] = true
        end
    end

    for i, category in ipairs(Config.WeaponWheel.categories) do
        weaponsInSlots[i] = nil
        for _, weapon in ipairs(category.weapons) do
            -- Check if weapon is in inventory OR equipped
            if inventoryWeapons[weapon] or HasPedGotWeapon(ped, GetHashKey(weapon), false) then
                local ammo = GetAmmoInPedWeapon(ped, GetHashKey(weapon)) or 0
                local displayName = weapon:gsub('weapon_', ''):gsub('_', ' '):upper()
                weaponsInSlots[i] = { weaponName = weapon, displayName = displayName, ammo = ammo }
                break
            end
        end
    end

    return weaponsInSlots
end

function EquipWeaponFromSlot(slot)
    local category = Config.WeaponWheel.categories[slot]
    if not category then return end

    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local inventory = PlayerData.items or {}
    
    -- Get all weapons from inventory
    local inventoryWeapons = {}
    for _, item in ipairs(inventory) do
        if item and item.name and string.find(item.name, 'weapon_') then
            inventoryWeapons[item.name] = item
        end
    end

    -- Find first available weapon in category from inventory
    for _, weapon in ipairs(category.weapons) do
        -- Check inventory first
        if inventoryWeapons[weapon] then
            TriggerServerEvent('QBCore:Server:UseItem', inventoryWeapons[weapon].slot)
            PlaySoundFrontend(-1, 'WEAPON_SELECT', 'HUD_AMMO_SHOP_SOUNDSET', true)
            return
        end
        -- Fallback to equipped weapon
        local hash = GetHashKey(weapon)
        if HasPedGotWeapon(ped, hash, false) then
            SetCurrentPedWeapon(ped, hash, true)
            PlaySoundFrontend(-1, 'WEAPON_SELECT', 'HUD_AMMO_SHOP_SOUNDSET', true)
            return
        end
    end
end

-- Quick weapon switch with 1-6 keys (use disabled control check since we disabled default)
CreateThread(function()
    while true do
        Wait(0)
        for i, key in ipairs(Config.WeaponWheel.quickSwitchKeys) do
            if IsDisabledControlJustPressed(0, key) then
                if not weaponWheelOpen then
                    currentSlot = i
                    EquipWeaponFromSlot(i)
                end
            end
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeAmmuNation', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('buyWeapon', function(data, cb)
    TriggerServerEvent('phantom_weapons:server:buyWeapon', data.weaponName)
    cb({})
end)

RegisterNUICallback('buyAmmo', function(data, cb)
    TriggerServerEvent('phantom_weapons:server:buyAmmo', data.weaponName, data.amount)
    cb({})
end)

RegisterNUICallback('buyTint', function(data, cb)
    TriggerServerEvent('phantom_weapons:server:buyTint', data.weaponName, data.tintId)
    cb({})
end)

RegisterNUICallback('buyAttachment', function(data, cb)
    TriggerServerEvent('phantom_weapons:server:buyAttachment', data.weaponName, data.attachment)
    cb({})
end)

-- Command to open weapon store
RegisterCommand('ammunation', function()
    OpenAmmuNation()
end)

-- Command to buy weapon license
RegisterCommand('weaponlicense', function()
    local coords = GetEntityCoords(PlayerPedId())
    local nearLocation = false

    for _, location in ipairs(Config.WeaponLicenseLocations) do
        if #(coords - location) < 5.0 then
            nearLocation = true
            break
        end
    end

    if not nearLocation then
        lib.notify({ title = 'Not Near City Hall', description = 'Go to City Hall to apply', type = 'error' })
        return
    end

    TriggerServerEvent('phantom_weapons:server:buyWeaponLicense')
end)

-- 3D Text helper
function Draw3DText(coords, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

print('^2[Phantom Weapons]^7 Client loaded')
