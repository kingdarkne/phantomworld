local interactions = {}
-- opens the ui
RegisterNetEvent('dr-elevator:showmenu', function(playerId)
    SendNUIMessage({action = 'showlift'})
    SetNuiFocus(true, true)
end)
-- hides the ui
RegisterNetEvent('dr-elevator:hidemenu', function(playerId)
    SendNUIMessage({action = 'hidelift'})
    SetNuiFocus(false, false)
end)

-- handles changing floors
local function UseElevator(data)
    local ped = PlayerPedId()
    local progressed = true
    if lib and lib.progressBar then
        progressed = lib.progressBar({
            duration = Config.WaitTime,
            label = Config.Locals[Config.UseLanguage].Waiting,
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
            },
            anim = {
                dict = "anim@apt_trans@elevator",
                clip = "elev_1",
                flag = 16,
            },
        }) == true
    else
        Wait(Config.WaitTime)
    end

    if not progressed then
        StopAnimTask(ped, "anim@apt_trans@elevator", "elev_1", 1.0)
        return
    end

    StopAnimTask(ped, "anim@apt_trans@elevator", "elev_1", 1.0)
    DoScreenFadeOut(500)
    Wait(1000)
    if Config.UseSoundEffect then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", Config.Elevators[data.lift].Sound, 0.05)
    end
    SetEntityCoords(ped, data.floor.Coords.x, data.floor.Coords.y, data.floor.Coords.z, 0, 0, 0, false)
    SetEntityHeading(ped, data.floor.Coords.w)
    Wait(1000)
    DoScreenFadeIn(600)
end

-- Function to add 3D TextUI interaction
function AddInteraction(index, coords)
    exports['j-textui']:create3DTextUI("elevator_"..index, {
        coords = coords, -- Location for interaction
        displayDist = 10.0, -- Distance at which the text is visible
        interactDist = 2.5, -- Distance within which the interaction is possible
        enableKeyClick = true, -- Enable key click interaction
        keyNum = 38, -- Key "E"
        key = "E", -- Interaction key
        text = "Press E to use the elevator", -- Text to display
        theme = "green", -- Theme color
        job = "all", -- Shows for all jobs
        canInteract = function()
            return true -- Add your condition here if needed
        end,
        triggerData = {
            triggerName = "dr-elevator:showmenu", -- Trigger event
            args = {} -- Arguments for the trigger
        }
    })
end

-- Create 3D TextUI targets from config
CreateThread(function()
    for k, v in pairs(Config.Elevator) do
        for _, location in ipairs(v.locations) do
            AddInteraction(k, location) -- Pass the index and location
        end
    end
end)





function NearestElevator()
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    
    local nearestElevator = nil
    local nearestDistance = math.huge

    for _, elevator in pairs(Config.Elevator) do 
        for _, location in ipairs(elevator.locations) do
            local distance = Vdist(playerCoords, location)
            
            if distance < nearestDistance then
                nearestElevator = elevator
                nearestDistance = distance
            end
        end
    end

    return nearestElevator, nearestDistance
end


RegisterNUICallback('selectfloor', function(data, cb)
    local floorNumber = tonumber(data.number)
    
    -- Get the nearest elevator and its floors
    local nearestElevator, nearestDistance = NearestElevator()
    if nearestElevator then
        local selectedFloor = nearestElevator.Floors[floorNumber]
        
        if selectedFloor then
            -- Call the UseElevator function with the elevator and floor data
            UseElevator({ lift = nearestElevator, floor = selectedFloor })
            cb({ success = true, message = "Floor selected successfully" })
            TriggerEvent("dr-elevator:hidemenu")
        else
            cb({ success = false, message = "Invalid floor selection" })
            TriggerEvent("dr-elevator:hidemenu")
        end
    else
        cb({ success = false, message = "No elevator found" })
    end
end)



RegisterNUICallback('escape', function(_, cb)
    TriggerEvent("dr-elevator:hidemenu")
    cb("ok")
end)
