-- Minimal QBX compat for this resource when qbx:enablebridge is off.
-- Provides only what qb-securityjob uses.

QBCore = QBCore or { Functions = {}, Commands = {} }

if IsDuplicityVersion() then
    QBCore.Functions.GetPlayer = QBCore.Functions.GetPlayer or function(source)
        return exports.qbx_core:GetPlayer(source)
    end

    QBCore.Functions.CreateCallback = QBCore.Functions.CreateCallback or function(name, cb)
        lib.callback.register(name, cb)
    end

    QBCore.Commands.Add = QBCore.Commands.Add or function(name, _, _, _, cb, permission)
        RegisterCommand(name, function(source, args)
            if source == 0 then return end
            if permission and not IsPlayerAceAllowed(source, permission) and not IsPlayerAceAllowed(source, 'admin') then
                TriggerClientEvent('ox_lib:notify', source, { title = 'Job', description = 'No permission', type = 'error' })
                return
            end
            cb(source, args)
        end, false)
    end
else
    QBCore.Functions.GetPlayerData = QBCore.Functions.GetPlayerData or function()
        return exports.qbx_core:GetPlayerData() or {}
    end

    QBCore.Functions.TriggerCallback = QBCore.Functions.TriggerCallback or function(name, cb, ...)
        local args = { ... }
        CreateThread(function()
            local res = { lib.callback.await(name, false, table.unpack(args)) }
            if cb then cb(table.unpack(res)) end
        end)
    end

    QBCore.Functions.DrawText = QBCore.Functions.DrawText or function(text)
        if text then lib.showTextUI(text) end
    end

    QBCore.Functions.HideText = QBCore.Functions.HideText or function()
        lib.hideTextUI()
    end

    if not QBCore.__notifyEventRegistered then
        QBCore.__notifyEventRegistered = true
        RegisterNetEvent('QBCore:Notify', function(msg, nType)
            lib.notify({ title = 'Job', description = msg, type = nType or 'inform' })
        end)
    end
end

