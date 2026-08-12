
Nuimessage = function (type,data)
    SendNUIMessage({
        action = type,
        data = data
    })
end

Nuicontrol = function (state)
    SetNuiFocus(state, state)
end


loadModel = function(model)
    if type(model) == 'string' then model = joaat(model) end
    if not model or model == 0 then return false end
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local deadline = GetGameTimer() + 8000
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then
            print(('[Multicharacter] model load timeout: %s'):format(tostring(model)))
            return false
        end
        Wait(10)
    end
    return true
end

GetPlayerMaxSlots = function(user)
    local extraslots = lib.callback.await('IV:GetExtraSlots', false,user)
    local slots = Config.Maxslots
    pcall(function ()
        slots = slots + extraslots
    end)

    return slots
end


DisableWeatherSync = function ()
    TriggerEvent('qb-weathersync:client:DisableSync')
end

EnableWeatherSync = function ()
    TriggerEvent('qb-weathersync:client:EnableSync')
end