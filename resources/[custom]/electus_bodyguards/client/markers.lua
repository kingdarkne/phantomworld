local currentAction = nil
local activeMarkers = {}
local markerPeds = {}

RegisterNetEvent("esx:setJob", function(job)
    RefreshPedShop()
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
    RefreshPedShop()
end)

local blips = {}

function AddBlip(coords, sprite, color, text, size, job)
    if(job ~= "none" and GetJob() ~= job) then
        return
    end
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, size)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = blip
end

RegisterNetEvent("electus_bodyguards:updateMarkerPeds", function(_markerPeds)
    markerPeds = _markerPeds
end)

for i=1,#Config.coords do
    exports["qtarget"]:AddTargetModel({Config.coords[i].model}, {
        options = {
            {
                label = "Interact",
                action = function()
                    OpenNPCProtectorShop(Config.coords[i].type)
                end,
                canInteract = function(entity)
                    if(Config.coords[i].requiredJob ~= "none") then
                        return GetJob() == Config.coords[i].requiredJob and markerPeds[i] and NetworkGetNetworkIdFromEntity(entity) == markerPeds[i].ped
                    end
                    return true and markerPeds[i] and NetworkGetNetworkIdFromEntity(entity) == markerPeds[i].ped
                end,
            }
        },
        distance = 2
    })
end

RegisterNetEvent("electus_bodyguards:spawnedMarkerPed", function(netId, type)
    while(not NetworkDoesEntityExistWithNetworkId(netId)) do
        Wait(0)
    end

    NetworkRequestControlOfNetworkId(netId)

    while(not NetworkHasControlOfNetworkId(netId)) do
        Wait(0)
    end

    local ped = NetworkGetEntityFromNetworkId(netId)

    while(not DoesEntityExist(ped)) do
        Wait(0)
    end

    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedDiesWhenInjured(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanPlayAmbientAnims(ped, false)
    PlaceObjectOnGroundProperly(ped)
end)


function RefreshPedShop()
    for i=1,#blips do
        RemoveBlip(blips[i])
    end

    local serverPeds = lib.callback.await("electus_bodyguards:getMarkerPeds", false)

    markerPeds = serverPeds

    for i=1,#Config.coords do
        if(Config.coords[i].requiredJob ~= "none") then
            while(GetJob == nil) do
                Wait(0)
            end
            if(GetJob() ~= Config.coords[i].requiredJob) then
                goto continue
            end
        end

        if(Config.coords[i].enableBlip) then
            local index = Config.coords[i].blipIndex
            AddBlip(Config.coords[i].coords, Config.blips[index].blipId, Config.blips[index].color, Config.blips[index].text, Config.blips[index].size, Config.blips[index].job)
        end
        ::continue::
    end
end

function OpenNPCProtectorShop(type)
    SendReactMessage("renderComponent", {component = "bodyguardShop", toSend = {ownedPeds = Bodyguards, shop = Config.shop[type:lower()], type = type:lower()}})
    ToggleNuiFrame(true)
end

CreateThread(function ()
    while(true) do
        Wait(1000)

        for i=1, #Config.coords do
            local coords = Config.coords[i].coords
            local dist = #(GetEntityCoords(PlayerPedId()) - coords)

            if(dist < 50.0) then
                -- for j=1, #markerPeds do
                    if(not markerPeds[i] or not NetworkDoesEntityExistWithNetworkId(markerPeds[i].ped)) then
                        TriggerServerEvent("electus_bodyguards:spawnMarkerPed", i)
                    end
                -- end
            end
        end
    end
end)

local hasBeenMsged = false

CreateThread(function()
    if(Config.targetSystem == "none") then
        while(true) do
            Wait(2500)
            local pedCoords = GetEntityCoords(PlayerPedId())
            for i=1,#Config.coords do
                if(#(Config.coords[i].coords - pedCoords) < 50.0) then
                    if(Config.coords[i].requiredJob ~= "none") then
                        if(GetJob() ~= Config.coords[i].requiredJob) then
                            goto continue
                        end
                    end
                    table.insert(activeMarkers, i)
                end
            end
            ::continue::
        end
    end
end)

CreateThread(function()
    while(true) do
        Wait(1000)
        if(#activeMarkers > 0) then
            local pedCoords = GetEntityCoords(PlayerPedId())
            for i=1,#activeMarkers do
                local dist = #(Config.coords[activeMarkers[i]].coords - pedCoords)
                if(dist < 2.0) then
                    currentAction = Config.coords[activeMarkers[i]].type
                elseif(currentAction == Config.coords[activeMarkers[i]].type) then
                    currentAction = nil
                elseif(dist >= 50.0) then
                    table.remove(activeMarkers, i)
                    lib.hideTextUI()
                    break
                end
                if(not hasBeenMsged and dist < 2.0) then
                    HelpText(L("open", {["key"] = Config.keyActions.openShop}))
                    hasBeenMsged = true
                elseif(hasBeenMsged and dist > 2.0) then
                    lib.hideTextUI()
                    hasBeenMsged = false
                end
            end
        end
    end
end)

function GetClosestBodyguardSlot()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local closest = 1000.0
    local slot = nil
    for k, v in pairs(Bodyguards) do
        local dist = #(GetEntityCoords(v.ped) - pedCoords)
        if(dist < closest) then
            closest = dist
            slot = v.slot
        end
    end

    if(closest < 2.0) then
        return slot
    end
end

CreateThread(function()
    local slot, closest = nil, 0.0
    local hasBeenMsged = nil
    while(Config.targetSystem == "none") do
        Wait(500)
        local pedCoords = GetEntityCoords(PlayerPedId())

        if(#Bodyguards > 0) then
            for k, v in pairs(Bodyguards) do
                local dist = #(GetEntityCoords(v.ped) - pedCoords)
                if(dist < closest or closest == 0.0) then
                    closest = dist
                    slot = v.slot
                end
            end
            if(closest < 2.0 and not hasBeenMsged) then
                hasBeenMsged = true
                HelpText(L("interactBodyguard", {["key"] = Config.keyActions.interactBodyguard}))
            elseif(closest > 2.0 and hasBeenMsged) then
                hasBeenMsged = nil
                local isOpen, text = lib.isTextUIOpen()

                if(isOpen and text == L("interactBodyguard", {["key"] = Config.keyActions.interactBodyguard})) then
                    lib.hideTextUI()
                end
            end
        else
            local isOpen, text = lib.isTextUIOpen()

            if(isOpen and text == L("interactBodyguard", {["key"] = Config.keyActions.interactBodyguard})) then
                lib.hideTextUI()
            end
        end
    end
end)

function GetClosestBodyguard()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local closest = 1000.0
    local slot = nil

    for k, v in pairs(Bodyguards) do
        local dist = #(GetEntityCoords(v.ped) - pedCoords)
        if(dist < closest or closest == 0.0) then
            closest = dist
            slot = v.slot
        end
    end

    return slot, closest
end

RegisterCommand('bodyguard_stay', function()
    for k, v in pairs(Bodyguards) do
        v.task = "stayPut"
        ClearPedTasks(v.ped)
    end
end, false)

RegisterCommand('bodyguard_follow', function()
    for k, v in pairs(Bodyguards) do
        v.task = nil
    end
end, false)

function InteractWithBodyguard()
    local slot, closest = GetClosestBodyguard()
    if(slot and closest < 2.0) then
        InteractBodyguard(Bodyguards[slot])
    end
end

function OpenBodyguardShop()
    if(currentAction) then
        OpenNPCProtectorShop(currentAction)
    end
end

lib.addKeybind({
    name = "interact_bodyguard",
    description = "Interact with bodyguard",
    defaultKey = Config.keyActions.interactBodyguard,
    onPressed = function ()
        OpenBodyguardShop()
    end,
})

lib.addKeybind({
    name = "bodyguard_shop",
    description = "Open Bodyguard shop",
    defaultKey = Config.keyActions.openShop,
    onPressed = function ()
        OpenBodyguardShop()
    end,
})