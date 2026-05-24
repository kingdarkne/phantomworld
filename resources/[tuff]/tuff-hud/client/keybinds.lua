local Strings = require 'shared.strings'
local KeyBinds = require 'shared.keybinds'

RegisterCommand("seatbelt", function()
    if not Client?.Vehicle then return end
    if not Client.Functions.IsSeatbeltAllowed(Client.Vehicle) then
        Client.Functions.SetSeatbeltState(false)
        FrameWork?.Functions?.Notify(Strings?.Notifications?.SeatbeltDisabled?.title or "Seatbelt Unavailable",
            Strings?.Notifications?.SeatbeltDisabled?.description or "You cannot use a seatbelt in this vehicle.",
            "error", 3000)
        return
    end

    Client.Functions.SetSeatbeltState(not Client.Seatbelt)
end, false)

RegisterKeyMapping("seatbelt", Strings?.CommandDesc?.seatbelt, "keyboard", KeyBinds?.seatbelt)

RegisterCommand("toggleengine", function()
    if not Client?.Vehicle then return end

    local veh = Client.Vehicle
    local IsRunning = GetIsVehicleEngineRunning(veh)

    SetVehicleEngineOn(veh, not IsRunning, 1, 1)
end, false)

RegisterKeyMapping("toggleengine", Strings?.CommandDesc?.engine, "keyboard", KeyBinds?.engine)

Client.Functions.UpdateKeyBinds = function()
    SendNUIMessage({
        type = "updateKeybinds",
        keybinds = KeyBinds
    })
end
