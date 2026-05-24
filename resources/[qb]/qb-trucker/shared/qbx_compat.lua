-- Minimal QBX compat for this resource when qbx:enablebridge is off.
-- Provides only what qb-trucker uses.

QBCore = QBCore or { Functions = {}, Commands = {} }

if IsDuplicityVersion() then
    QBCore.Functions.GetPlayer = QBCore.Functions.GetPlayer or function(source)
        return exports.qbx_core:GetPlayer(source)
    end
else
    QBCore.Functions.GetPlayerData = QBCore.Functions.GetPlayerData or function()
        return exports.qbx_core:GetPlayerData() or {}
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

