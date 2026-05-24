QBCore = QBCore or { Functions = {}, Commands = {}, Shared = { Items = {}, Weapons = {} } }
QBCore.Functions = QBCore.Functions or {}
QBCore.Commands = QBCore.Commands or {}
QBCore.Shared = QBCore.Shared or { Items = {}, Weapons = {} }

if not IsDuplicityVersion() then
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

    QBCore.Functions.Notify = QBCore.Functions.Notify or function(msg, nType)
        lib.notify({ description = msg, type = nType or 'inform' })
    end

    QBCore.Functions.DrawText = QBCore.Functions.DrawText or function(text)
        if text then lib.showTextUI(text) end
    end

    QBCore.Functions.HideText = QBCore.Functions.HideText or function()
        lib.hideTextUI()
    end

    QBCore.Functions.KeyPressed = QBCore.Functions.KeyPressed or function(_)
        -- no-op for qb-core prompt pulse compatibility
    end
end
