--[[
  Native GTA weapon wheel bridge (no NUI).

  The old custom NUI wheel used SetNuiFocus(true, true), which unlocked the
  mouse and frequently left players unable to move. This resource only:
    1) turns on ox_inventory's GTA wheel + inventory weapon seeding
    2) clears stuck NUI focus (/freemouse)
]]

local function clearStuckFocus(reason)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    if reason then
        print(('[gta_weapon_wheel] cleared NUI focus (%s)'):format(reason))
    end
end

local function enableNativeWheel()
    if GetResourceState('ox_inventory') ~= 'started' then return false end

    -- Seed ped weapons from inventory and allow TAB wheel
    pcall(function()
        exports.ox_inventory:Weaponsyncdisable(false)
    end)
    pcall(function()
        exports.ox_inventory:weaponWheel(true)
    end)
    return true
end

CreateThread(function()
    clearStuckFocus('resource_start')

    for _ = 1, 30 do
        if enableNativeWheel() then break end
        Wait(500)
    end

    print('^2[Weapon Wheel]^7 Native GTA wheel enabled — hold TAB (no mouse unlock)')
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= 'ox_inventory' then return end
    CreateThread(function()
        Wait(1500)
        enableNativeWheel()
    end)
end)

-- Re-seed so newly looted weapons appear on the wheel
CreateThread(function()
    while true do
        Wait(5000)
        if GetResourceState('ox_inventory') == 'started' then
            pcall(function()
                exports.ox_inventory:weaponWheel(true)
            end)
        end
    end
end)

RegisterCommand('freemouse', function()
    clearStuckFocus('command')
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('Mouse/UI focus cleared — you can move again.')
    EndTextCommandThefeedPostTicker(false, true)
end, false)

RegisterCommand('fixcursor', function()
    ExecuteCommand('freemouse')
end, false)

-- ESC while focused (and inventory is not open) → clear stuck focus
CreateThread(function()
    while true do
        if IsNuiFocused() then
            if IsControlJustPressed(0, 322) then -- ESC
                Wait(150)
                if IsNuiFocused() then
                    local invOpen = LocalPlayer.state and LocalPlayer.state.invOpen == true
                    if not invOpen then
                        clearStuckFocus('escape')
                    end
                end
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)
