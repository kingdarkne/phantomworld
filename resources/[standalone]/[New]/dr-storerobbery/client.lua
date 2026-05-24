local function IsClerkPed(entity)
    if not DoesEntityExist(entity) or not IsPedAPlayer(entity) and not IsPedHuman(entity) then
        -- still allow NPC humans, just avoid weird entities
    end
    local model = GetEntityModel(entity)
    for _, m in ipairs(Config.StoreClerkModels or {}) do
        if model == m then
            return true
        end
    end
    return false
end

local function GetClosestRegisterToCoords(coords)
    if not Config.Registers or not next(Config.Registers) then return nil end
    local closest, idx, dist = nil, nil, 9999.0
    for i, reg in ipairs(Config.Registers) do
        local d = #(coords - reg.coords)
        if d < dist then
            dist = d
            closest = reg
            idx = i
        end
    end
    return idx, closest, dist
end

-- Start robbery when called with a register index
RegisterNetEvent('dr-storerobbery:client:useRegister', function(index)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local ok = lib.progressBar({
        duration = Config.RobTime,
        label = 'Grabbing cash...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@prop_human_bum_bin@idle_a', clip = 'idle_a', flag = 49 },
    })

    ClearPedTasks(ped)
    if ok then
        TriggerServerEvent('dr-storerobbery:server:tryRob', index)
    end
end)

-- Police blip when robbery happens
RegisterNetEvent('dr-storerobbery:client:blip', function(index)
    local reg = Config.Registers[index]
    if not reg then return end
    local blip = AddBlipForCoord(reg.coords.x, reg.coords.y, reg.coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.2)
    if Config.RedRegisters and Config.RedRegisters[index] then
        SetBlipColour(blip, 1) -- red for high risk
    else
        SetBlipColour(blip, 5) -- blue for normal
    end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Store Robbery')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, false)
    PulseBlip(blip)
    Citizen.SetTimeout(60000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

-- Main loop: point a gun at the clerk, press E to rob
CreateThread(function()
    local showHelp = false
    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if IsPedArmed(ped, 4) and IsPlayerFreeAiming(PlayerId()) then
            sleep = 5
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if entity and DoesEntityExist(entity) and IsEntityAPed(entity) and IsClerkPed(entity) then
                local pCoords = GetEntityCoords(ped)
                local cCoords = GetEntityCoords(entity)
                local dist = #(pCoords - cCoords)
                if dist < 5.0 then
                    local idx, _, regDist = GetClosestRegisterToCoords(cCoords)
                    if idx and regDist < 10.0 then
                        showHelp = true
                        SetTextComponentFormat('STRING')
                        AddTextComponentString('Press ~INPUT_CONTEXT~ to rob the register')
                        DisplayHelpTextFromStringLabel(0, false, true, -1)

                        if IsControlJustPressed(0, 38) then -- E
                            TriggerEvent('dr-storerobbery:client:useRegister', idx)
                            Wait(1000)
                        end
                    end
                end
            end
        end

        if not showHelp then
            -- no-op; help text auto fades
        else
            showHelp = false
        end

        Wait(sleep)
    end
end)

