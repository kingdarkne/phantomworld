local chestTextActive = false

local function applyMaleVest(ped)
    SetPedComponentVariation(ped, 8, 15, 0, 2)
    SetPedComponentVariation(ped, 11, 27, 2, 2)
    SetPedComponentVariation(ped, 9, 4, 1, 2)
end

local function applyFemaleVest(ped)
    SetPedComponentVariation(ped, 8, 14, 0, 2)
    SetPedComponentVariation(ped, 11, 25, 2, 2)
    SetPedComponentVariation(ped, 9, 4, 1, 2)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.0, 0.7)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(0, 255, 0, 255) -- bright green
    SetTextCentre(true)
    SetTextOutline()

    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterNetEvent('dr-ownervest:client:applyVest', function()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)

    if model == GetHashKey('mp_m_freemode_01') then
        applyMaleVest(ped)
        chestTextActive = true
        lib.notify({ title = 'Owner Vest', description = 'Owner vest applied.', type = 'success' })
    elseif model == GetHashKey('mp_f_freemode_01') then
        applyFemaleVest(ped)
        chestTextActive = true
        lib.notify({ title = 'Owner Vest', description = 'Owner vest applied.', type = 'success' })
    else
        lib.notify({ title = 'Owner Vest', description = 'Owner vest only works on MP freemode characters.', type = 'error' })
    end
end)

-- Command to toggle vest
RegisterCommand('ownervest', function()
    TriggerServerEvent('dr-ownervest:server:requestVest')
end)

-- Draw big green OWNER text in the center of the chest when vest is active
CreateThread(function()
    while true do
        Wait(0)
        if chestTextActive then
            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then
                chestTextActive = false
            else
                -- Use an upper-spine bone and push text slightly forward so it appears on chest
                local boneCoords = GetPedBoneCoords(ped, 0x5C01, 0.0, 0.15, 0.0) -- SKEL_Spine3 / chest area
                DrawText3D(boneCoords.x, boneCoords.y, boneCoords.z, 'OWNER')
            end
        end
    end
end)

