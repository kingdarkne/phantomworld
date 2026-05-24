-- Minimal QBX compat for this resource when qbx:enablebridge is off.
-- Provides only what qb-towjob uses.

QBCore = QBCore or { Functions = {}, Commands = {} }

if IsDuplicityVersion() then
    QBCore.Functions.GetPlayer = QBCore.Functions.GetPlayer or function(source)
        return exports.qbx_core:GetPlayer(source)
    end

    QBCore.Commands.Add = QBCore.Commands.Add or function(name, _, _, _, cb)
        RegisterCommand(name, function(source, args)
            if source == 0 then return end
            cb(source, args)
        end, false)
    end
else
    QBCore.Functions.GetPlayerData = QBCore.Functions.GetPlayerData or function()
        return exports.qbx_core:GetPlayerData() or {}
    end

    if not QBCore.__notifyEventRegistered then
        QBCore.__notifyEventRegistered = true
        RegisterNetEvent('QBCore:Notify', function(msg, nType)
            lib.notify({ title = 'Job', description = msg, type = nType or 'inform' })
        end)
    end
end

