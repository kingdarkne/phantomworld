local QBCore = QBCore or { Functions = {}, Shared = { Items = {} } }
QBCore.Functions = QBCore.Functions or {}
QBCore.Shared = QBCore.Shared or { Items = {} }
QBCore.Functions.GetPlayer = QBCore.Functions.GetPlayer or function(src) return exports.qbx_core:GetPlayer(src) end

RegisterNetEvent('jomidar:mosleys:removeItem', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local itemData = Player.Functions.GetItemByName(item)
        if itemData and itemData.amount > 0 then
            exports.ox_inventory:RemoveItem(source, item, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "remove")
        else
            TriggerClientEvent('QBCore:Notify', src, "You don't have the required item", "error")
        end
    end
end)

RegisterNetEvent('dr-mosleys:addmoney', function(vehicleQuality)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local amount = 0
        local tipAmount = 0

        if vehicleQuality == 1000 then
            amount = Config.PaymentIfvehiclehealth100
            
            -- Check if tips are enabled
            if Config.Tip then
                tipAmount = amount * (Config.TipPercentage / 100)
                amount = amount + tipAmount
                TriggerClientEvent('QBCore:Notify', src, "You Got "..amount.."$ (including tip of "..tipAmount.."$)", "success")
            else
                TriggerClientEvent('QBCore:Notify', src, "You Got "..amount.."$", "success")
            end

            Player.Functions.AddMoney('cash', amount, 'dr-mosleysTip')
        elseif vehicleQuality >= 500 and vehicleQuality < 1000 then
            amount = Config.PaymentIfvehiclehealth50
            TriggerClientEvent('QBCore:Notify', src, "You Got "..amount.."$", "success")
            Player.Functions.AddMoney('cash', amount, 'dr-mosleys:addmoney')
        elseif vehicleQuality >= 0 and vehicleQuality < 500 then
            amount = Config.PaymentIfvehiclehealthunder500
            TriggerClientEvent('QBCore:Notify', src, "You Got "..amount.."$", "success")
            Player.Functions.AddMoney('cash', amount, 'dr-mosleys:addmoney')
        end
    end
end)

