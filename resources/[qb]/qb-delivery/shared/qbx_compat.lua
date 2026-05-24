-- Minimal QBX compat for this resource when qbx:enablebridge is off.
-- Provides only what qb-delivery uses.

QBCore = QBCore or { Functions = {} }

if IsDuplicityVersion() then
    QBCore.Functions.GetPlayer = QBCore.Functions.GetPlayer or function(source)
        return exports.qbx_core:GetPlayer(source)
    end
else
    QBCore.Functions.GetPlayerData = QBCore.Functions.GetPlayerData or function()
        return exports.qbx_core:GetPlayerData() or {}
    end

    QBCore.Functions.Notify = QBCore.Functions.Notify or function(msg, nType)
        lib.notify({ title = 'Delivery', description = msg, type = nType or 'inform' })
    end

    if not QBCore.__notifyEventRegistered then
        QBCore.__notifyEventRegistered = true
        RegisterNetEvent('QBCore:Notify', function(msg, nType)
            lib.notify({ title = 'Delivery', description = msg, type = nType or 'inform' })
        end)
    end
end

