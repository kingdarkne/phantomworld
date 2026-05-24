-- Phantom Heists - Main Client
local QBCore = exports['qbx_core']:GetCoreObject()
local currentHeist = nil
local heistActive = false
local heistPhase = 'idle'
local nearHeist = false
local lootCarrying = 0
local maxLoot = 3
local heistBlips = {}

-- Initialize
CreateThread(function()
    Wait(2000)
    CreateHeistBlips()
    print('^2[Phantom Heists]^7 Client initialized')
end)

-- Create blips for heist locations
function CreateHeistBlips()
    for _, heist in ipairs(Config.Heists) do
        if heist.blip then
            local blip = AddBlipForCoord(heist.coords.x, heist.coords.y, heist.coords.z)
            SetBlipSprite(blip, heist.blip.sprite)
            SetBlipColour(blip, heist.blip.color)
            SetBlipScale(blip, heist.blip.scale)
            SetBlipAsShortRange(blip, true)
            SetBlipDisplay(blip, 4)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(heist.name)
            EndTextCommandSetBlipName(blip)
            heistBlips[heist.id] = blip
        end
    end
end

-- Main thread - check proximity to heists
CreateThread(function()
    while true do
        Wait(1000)
        if not heistActive then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            nearHeist = false
            currentHeist = nil

            for _, heist in ipairs(Config.Heists) do
                local dist = #(coords - heist.coords)
                if dist < 30.0 then
                    nearHeist = true
                    currentHeist = heist
                    break
                end
            end
        end
    end
end)

-- Draw markers and interaction prompts
CreateThread(function()
    while true do
        Wait(0)
        if nearHeist and not heistActive and currentHeist then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heist = currentHeist

            -- Draw marker at entrance
            DrawMarker(1, heist.coords.x, heist.coords.y, heist.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 0.5, 255, 50, 50, 100, false, false, 2, false, nil, nil, false)

            -- Show prompt
            local dist = #(coords - heist.coords)
            if dist < 2.0 then
                Draw3DText(heist.coords + vec3(0, 0, 1.0), '~r~[E]~w~ Start ' .. heist.name .. ' Heist\n~y~Cost: $' .. heist.setupCost, 0.35, 4)

                if IsControlJustPressed(0, 38) then -- E key
                    AttemptStartHeist(heist)
                end
            end
        end

        if heistActive then
            HandleHeistPhases()
        end
    end
end)

-- Attempt to start a heist
function AttemptStartHeist(heist)
    -- Check cooldown
    local canStart = lib.callback.await('phantom_heists:server:checkCooldown', false, heist.id)
    if not canStart then
        lib.notify({ title = 'Heist Unavailable', description = 'This location is on cooldown', type = 'error' })
        return
    end

    -- Check police count
    local policeCount = lib.callback.await('phantom_heists:server:getPoliceCount', false)
    local required = Config.PoliceRequired[heist.type] or 2
    if policeCount < required then
        lib.notify({ title = 'Not Enough Police', description = 'Need at least ' .. required .. ' cops online (' .. policeCount .. ')', type = 'error' })
        return
    end

    -- Confirm start
    local alert = lib.alertDialog({
        header = heist.name,
        content = 'Difficulty: ' .. heist.difficulty:upper() .. '\nSetup Cost: $' .. heist.setupCost .. '\nEstimated Payout: $' .. heist.payoutMin .. ' - $' .. heist.payoutMax .. '\nPolice Required: ' .. required .. '\n\nAre you ready?',
        centered = true,
        cancel = true,
        labels = { confirm = 'START HEIST', cancel = 'Cancel' }
    })

    if alert ~= 'confirm' then return end

    -- Start heist
    local success = lib.callback.await('phantom_heists:server:startHeist', false, heist.id)
    if success then
        heistActive = true
        heistPhase = 'hack'
        lootCarrying = 0
        StartHeistSequence(heist)
    else
        lib.notify({ title = 'Heist Failed', description = 'Could not start heist', type = 'error' })
    end
end

-- Heist sequence handler
function StartHeistSequence(heist)
    lib.notify({ title = 'Heist Started!', description = heist.name .. ' - Phase 1: Hack the security system', type = 'info', duration = 10000 })

    -- Create blip for hack location
    local hackBlip = AddBlipForCoord(heist.hackCoords.x, heist.hackCoords.y, heist.hackCoords.z)
    SetBlipSprite(hackBlip, 161)
    SetBlipColour(hackBlip, 5)
    SetBlipRoute(hackBlip, true)

    -- Wait for hack phase
    CreateThread(function()
        local hacked = false
        while heistActive and heistPhase == 'hack' do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - heist.hackCoords)

            if dist < 1.5 then
                Draw3DText(heist.hackCoords + vec3(0, 0, 0.5), '~r~[E]~w~ Hack Security System', 0.35, 4)
                if IsControlJustPressed(0, 38) then
                    hacked = StartHackMinigame(heist.hackDuration)
                    if hacked then
                        RemoveBlip(hackBlip)
                        heistPhase = 'breach'
                        lib.notify({ title = 'Security Hacked!', description = 'Phase 2: Breach the vault', type = 'success', duration = 8000 })
                        StartBreachPhase(heist)
                    else
                        lib.notify({ title = 'Hack Failed!', description = 'Alarm triggered early!', type = 'error' })
                        TriggerServerEvent('phantom_heists:server:triggerAlarm', heist.id, true)
                    end
                end
            end
        end
        if not hacked then RemoveBlip(hackBlip) end
    end)
end

-- Breach phase (thermite/drill)
function StartBreachPhase(heist)
    local breachBlip = AddBlipForCoord(heist.vaultCoords.x, heist.vaultCoords.y, heist.vaultCoords.z)
    SetBlipSprite(breachBlip, 161)
    SetBlipColour(breachBlip, 1)
    SetBlipRoute(breachBlip, true)

    CreateThread(function()
        local breached = false
        while heistActive and heistPhase == 'breach' do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - heist.vaultCoords)

            if dist < 2.0 then
                if heist.type == 'pacific' or heist.type == 'paleto' then
                    Draw3DText(heist.vaultCoords + vec3(0, 0, 0.5), '~r~[E]~w~ Plant Thermite Charge', 0.35, 4)
                    if IsControlJustPressed(0, 38) then
                        local success = StartThermiteMinigame(heist.thermiteDuration or 15)
                        if success then
                            -- Thermite animation
                            PlayThermiteAnimation(heist.vaultCoords)
                            breached = true
                        else
                            lib.notify({ title = 'Thermite Failed!', description = 'Vault still sealed!', type = 'error' })
                        end
                    end
                else
                    Draw3DText(heist.vaultCoords + vec3(0, 0, 0.5), '~r~[E]~w~ Drill Vault Door', 0.35, 4)
                    if IsControlJustPressed(0, 38) then
                        local success = StartDrillMinigame(heist.drillDuration or 60)
                        if success then
                            breached = true
                        else
                            lib.notify({ title = 'Drill Failed!', description = 'Drill overheated!', type = 'error' })
                        end
                    end
                end

                if breached then
                    RemoveBlip(breachBlip)
                    heistPhase = 'loot'
                    lib.notify({ title = 'Vault Breached!', description = 'Phase 3: Grab the loot!', type = 'success', duration = 8000 })
                    StartLootPhase(heist)
                end
            end
        end
        if not breached then RemoveBlip(breachBlip) end
    end)
end

-- Loot phase
function StartLootPhase(heist)
    local lootBlips = {}

    if heist.type == 'jewelry' then
        -- Jewelry smashing
        for i, smashCoord in ipairs(heist.smashCoords) do
            local blip = AddBlipForCoord(smashCoord.x, smashCoord.y, smashCoord.z)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 2)
            SetBlipScale(blip, 0.5)
            table.insert(lootBlips, blip)
        end

        CreateThread(function()
            local smashedCount = 0
            local smashed = {}
            while heistActive and heistPhase == 'loot' do
                Wait(0)
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)

                for i, smashCoord in ipairs(heist.smashCoords) do
                    if not smashed[i] then
                        local dist = #(coords - smashCoord)
                        if dist < 1.0 then
                            Draw3DText(smashCoord + vec3(0, 0, 0.3), '~r~[E]~w~ Smash & Grab', 0.3, 4)
                            if IsControlJustPressed(0, 38) then
                                SmashJewelryCase(smashCoord)
                                smashed[i] = true
                                smashedCount = smashedCount + 1
                                lootCarrying = lootCarrying + 1

                                if smashedCount >= heist.smashCount then
                                    heistPhase = 'escape'
                                    lib.notify({ title = 'Loot Secured!', description = 'Phase 4: Escape!', type = 'success', duration = 8000 })
                                    StartEscapePhase(heist)
                                end
                            end
                        end
                    end
                end
            end
            for _, blip in ipairs(lootBlips) do RemoveBlip(blip) end
        end)
    else
        -- Bank vault loot
        local blip = AddBlipForCoord(heist.vaultCoords.x, heist.vaultCoords.y, heist.vaultCoords.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 2)
        table.insert(lootBlips, blip)

        CreateThread(function()
            local looted = 0
            while heistActive and heistPhase == 'loot' do
                Wait(0)
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local dist = #(coords - heist.vaultCoords)

                if dist < 2.0 then
                    Draw3DText(heist.vaultCoords + vec3(0, 0, 0.5), '~r~[E]~w~ Grab Loot (' .. looted .. '/' .. maxLoot .. ')', 0.35, 4)
                    if IsControlJustPressed(0, 38) then
                        GrabVaultLoot(heist)
                        looted = looted + 1
                        lootCarrying = lootCarrying + 1

                        if looted >= maxLoot then
                            heistPhase = 'escape'
                            lib.notify({ title = 'Loot Secured!', description = 'Phase 4: Escape with the loot!', type = 'success', duration = 8000 })
                            StartEscapePhase(heist)
                        end
                    end
                end
            end
            for _, b in ipairs(lootBlips) do RemoveBlip(b) end
        end)
    end
end

-- Escape phase
function StartEscapePhase(heist)
    local escapeBlip = AddBlipForCoord(heist.exitCoords.x, heist.exitCoords.y, heist.exitCoords.z)
    SetBlipSprite(escapeBlip, 1)
    SetBlipColour(escapeBlip, 5)
    SetBlipRoute(escapeBlip, true)

    CreateThread(function()
        while heistActive and heistPhase == 'escape' do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - heist.exitCoords)

            if dist < 5.0 then
                Draw3DText(heist.exitCoords + vec3(0, 0, 1.0), '~g~[E]~w~ Deliver Loot', 0.45, 4)
                if IsControlJustPressed(0, 38) then
                    -- Success!
                    RemoveBlip(escapeBlip)
                    TriggerServerEvent('phantom_heists:server:heistComplete', heist.id, lootCarrying)
                    heistActive = false
                    heistPhase = 'idle'
                    lootCarrying = 0
                    lib.notify({ title = 'Heist Complete!', description = 'You escaped with the loot!', type = 'success', duration = 10000 })
                    break
                end
            end
        end
        if heistActive then RemoveBlip(escapeBlip) end
    end)

    -- Timeout check
    CreateThread(function()
        Wait(300000) -- 5 minute escape timer
        if heistActive and heistPhase == 'escape' then
            heistActive = false
            heistPhase = 'idle'
            lootCarrying = 0
            lib.notify({ title = 'Heist Failed', description = 'You ran out of time!', type = 'error' })
        end
    end)
end

-- Smash jewelry case
function SmashJewelryCase(coords)
    local ped = PlayerPedId()
    -- Animation
    RequestAnimDict('missheist_jewel')
    while not HasAnimDictLoaded('missheist_jewel') do Wait(10) end
    TaskPlayAnim(ped, 'missheist_jewel', 'smash_case', 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(ped)

    -- Sound and particles
    PlaySoundFromCoord(-1, 'Glass_Smash', coords.x, coords.y, coords.z, 'GENERIC_SOUNDSET', false, 0, false)

    lib.notify({ title = 'Loot Grabbed', description = 'Jewelry secured!', type = 'success' })
end

-- Grab vault loot
function GrabVaultLoot(heist)
    local ped = PlayerPedId()
    RequestAnimDict('anim@heists@ornate_bank@grab_cash')
    while not HasAnimDictLoaded('anim@heists@ornate_bank@grab_cash') do Wait(10) end
    TaskPlayAnim(ped, 'anim@heists@ornate_bank@grab_cash', 'grab', 8.0, -8.0, 3000, 0, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(ped)

    -- Attach bag
    local bag = CreateObject(GetHashKey('prop_cs_heist_bag_01'), 0, 0, 0, true, true, true)
    AttachEntityToEntity(bag, ped, GetPedBoneIndex(ped, 60309), 0.1, -0.11, 0.08, 0.0, -75.0, -75.0, true, true, false, true, 0, true)

    lib.notify({ title = 'Loot Grabbed', description = 'Cash bag secured!', type = 'success' })
end

-- Thermite animation
function PlayThermiteAnimation(coords)
    -- Particle effect
    local fx = StartParticleFxLoopedAtCoord('ent_ray_heist_fleeca_bam', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    PlaySoundFromCoord(-1, 'Explosion_Large', coords.x, coords.y, coords.z, 'GENERIC_SOUNDSET', false, 0, false)
    Wait(3000)
    StopParticleFxLooped(fx, false)
end

-- Handle heist phases UI
function HandleHeistPhases()
    if heistPhase ~= 'idle' then
        local phaseNames = { hack = 'HACK SECURITY', breach = 'BREACH VAULT', loot = 'GRAB LOOT', escape = 'ESCAPE!' }
        local phaseText = phaseNames[heistPhase] or ''
        DrawTxt(0.5, 0.92, 0.8, phaseText, 4, 255, 50, 50, 255, true)

        if lootCarrying > 0 then
            DrawTxt(0.5, 0.95, 0.4, 'Loot: ' .. lootCarrying .. ' bags', 4, 255, 215, 0, 255, true)
        end
    end
end

-- Draw text helper
function DrawTxt(x, y, scale, text, font, r, g, b, a, centered)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    if centered then SetTextCentre(1) end
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

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

-- Cancel heist command
RegisterCommand('cancelheist', function()
    if heistActive then
        heistActive = false
        heistPhase = 'idle'
        lootCarrying = 0
        lib.notify({ title = 'Heist Cancelled', type = 'info' })
    end
end)

-- Police alert notification
RegisterNetEvent('phantom_heists:client:policeAlert', function(data)
    if QBCore.Functions.GetPlayerData().job.name == 'police' then
        lib.notify({
            title = '🚨 ' .. data.title,
            description = data.message .. '\nLocation: ' .. data.location,
            type = 'error',
            duration = 15000,
            position = 'top-right'
        })

        -- Add map blip
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, Config.Dispatch.blipSprite)
        SetBlipColour(blip, Config.Dispatch.blipColor)
        SetBlipScale(blip, Config.Dispatch.blipScale)
        SetBlipFlashes(blip, true)
        SetBlipFlashInterval(blip, 500)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('ACTIVE HEIST')
        EndTextCommandSetBlipName(blip)

        -- Remove after duration
        CreateThread(function()
            Wait(Config.Dispatch.flashDuration * 1000)
            RemoveBlip(blip)
        end)
    end
end)

print('^2[Phantom Heists]^7 Client loaded')
