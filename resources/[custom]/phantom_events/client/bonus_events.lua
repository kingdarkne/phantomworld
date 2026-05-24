-- Phantom Events - Bonus Events (Double XP, Payday, VIP)

local activeBonuses = {}

function StartBonusEvent(eventType, data)
    activeBonuses[eventType] = true

    local messages = {
        doubleXP = 'Double XP is active! Earn 2x XP on all skills!',
        doublePayday = 'Double Payday! All jobs pay 2x!',
    }

    lib.notify({
        title = '✨ ' .. data.name:upper() .. ' ACTIVE!',
        description = messages[eventType] or data.description,
        type = 'success',
        duration = 10000,
    })

    -- Display floating text reminder
    CreateThread(function()
        while activeBonuses[eventType] do
            Wait(300000) -- Every 5 minutes
            if activeBonuses[eventType] then
                lib.notify({
                    title = '✨ Bonus Still Active!',
                    description = data.name .. ' is still running!',
                    type = 'info',
                    duration = 5000,
                })
            end
        end
    end)
end

function StartVIPBonus(data)
    activeBonuses['vipBonus'] = true

    lib.notify({
        title = '👑 VIP BONUS HOUR!',
        description = 'Store/Fuel/Repair discounts + Bank interest boost!',
        type = 'success',
        duration = 10000,
    })

    -- Show perk list
    local perks = Config.Events.vipBonus.vipPerks
    lib.notify({
        title = 'VIP Perks:',
        description = string.format('Store: -%d%% | Fuel: -%d%% | Repair: -%d%% | Bank: +%d%% interest',
            perks.storeDiscount * 100, perks.fuelDiscount * 100, perks.repairDiscount * 100, perks.bankInterest * 100),
        type = 'info',
        duration = 8000,
    })
end

-- Exports for other resources to check active bonuses
exports('IsDoubleXP', function()
    return activeBonuses['doubleXP'] or false
end)

exports('IsDoublePayday', function()
    return activeBonuses['doublePayday'] or false
end)

exports('IsVIPBonus', function()
    return activeBonuses['vipBonus'] or false
end)
