carMenuOpen = false

local function closeCarMenu()
    carMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "openCarMenu", state = false })
end

local function getPlayerSeat(veh)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(veh)
    for seat = -1, maxPassengers - 1 do
        if GetPedInVehicleSeat(veh, seat) == PlayerPedId() then
            return seat
        end
    end
    return -1
end

local function openCarMenu()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        return
    end

    local mySeat = getPlayerSeat(veh)
    local doorData = {}
    local seatCount = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    local doorNum = math.max(seatCount - 1, 0)

    for i = 0, doorNum do
        doorData[#doorData + 1] = {
            doorNum = tostring(i),
            opened = GetVehicleDoorAngleRatio(veh, i) > 0.0,
        }
    end

    local _, lights, highbeams = GetVehicleLightsState(veh)

    carMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openCarMenu",
        resourceName = GetCurrentResourceName(),
        state = true,
        align = Config.Menu.Align,
        styleType = Config.Menu.StyleType,
        carData = {
            doorNum = seatCount,
            doorData = doorData,
            vehConvertible = IsVehicleAConvertible(veh, false),
            vehConvertibleState = GetConvertibleRoofState(veh),
            engineState = GetIsVehicleEngineRunning(veh) and 1 or 0,
            playerSeat = mySeat,
            intLightState = IsVehicleInteriorLightOn(veh) and 1 or 0,
            lightsOn = lights,
            highbeamsOn = highbeams,
            trunk = GetVehicleDoorAngleRatio(veh, 5) > 0.0,
            hood = GetVehicleDoorAngleRatio(veh, 4) > 0.0,
            indicatorState = GetVehicleIndicatorLights(veh),
        },
    })
end

RegisterCommand(Config.Menu.Command, function()
    if carMenuOpen then
        closeCarMenu()
        return
    end
    openCarMenu()
end)

-- Escape hatch if focus ever sticks (/closecarmenu or toggle /carmenu again)
RegisterCommand('closecarmenu', function()
    closeCarMenu()
end)

RegisterNUICallback('callback', function(data, cb)
    local action = data and data.action
    if action == "nuiFocus" then
        closeCarMenu()
        cb('ok')
        return
    end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        cb('ok')
        return
    end

    if action == "convertVeh" then
        if data.state == false then
            RaiseConvertibleRoof(veh, false)
        else
            LowerConvertibleRoof(veh, false)
        end
    elseif action == "window" then
        local num = (tonumber(data.num) or 1) - 1
        if data.state == true then
            RollDownWindow(veh, num)
        else
            RollUpWindow(veh, num)
        end
    elseif action == "changeSeat" then
        if data.num == "driver" then
            if IsVehicleSeatFree(veh, -1) then
                SetPedIntoVehicle(PlayerPedId(), veh, -1)
            end
        else
            local num = tonumber(data.num)
            if num ~= nil and IsVehicleSeatFree(veh, num) then
                SetPedIntoVehicle(PlayerPedId(), veh, num)
            end
        end
    elseif action == "engine" then
        if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            SetVehicleEngineOn(veh, data.state and true or false, false, true)
        end
    elseif action == "alarm" then
        SetVehicleAlarm(veh, data.state and true or false)
        if data.state == true then
            StartVehicleAlarm(veh)
            SetVehicleAlarmTimeLeft(veh, Config.AlarmDuration)
            CreateThread(function()
                Wait(Config.AlarmDuration)
                SendNUIMessage({ action = "closeAlarm" })
            end)
        end
    elseif action == "intLight" then
        SetVehicleInteriorlight(veh, data.state and true or false)
    elseif action == "lights" then
        if data.name == "normal" then
            SetVehicleLights(veh, 1)
            Wait(500)
            SetVehicleLights(veh, 3)
            SetVehicleFullbeam(veh, false)
        elseif data.name == "highbeams" then
            SetVehicleLights(veh, 1)
            Wait(500)
            SetVehicleLights(veh, 3)
            SetVehicleFullbeam(veh, true)
        end
    elseif action == "door" then
        local doorId = data.number
        if doorId == "trunk" then
            doorId = 5
        elseif doorId == "hood" then
            doorId = 4
        else
            doorId = tonumber(doorId)
        end
        if doorId ~= nil then
            if data.state == true then
                SetVehicleDoorOpen(veh, doorId, false, false)
            else
                SetVehicleDoorShut(veh, doorId, false)
            end
        end
    elseif action == "indicator" then
        SetVehicleIndicatorLights(veh, tonumber(data.name) or 0, data.state and true or false)
    end

    cb('ok')
end)

RegisterNetEvent('dr-carcontrol:openMenu', function()
    if carMenuOpen then
        closeCarMenu()
    else
        openCarMenu()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and carMenuOpen then
        SetNuiFocus(false, false)
    end
end)
