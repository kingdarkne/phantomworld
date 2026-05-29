local QBCore = exports['qb-core']:GetCoreObject()

local SafeCodes = {}
local activeRegisterRobbers = {}
local activeSafeRobbers = {}

local function getRegisterTable()
    return Config.UseGabz and Config.RegistersTargetGabz or Config.RegistersTarget
end

local function getSafeTable()
    return Config.UseGabz and Config.SafesTargetGabz or Config.SafesTarget
end

local function isPlayerNearTarget(src, target, maxDistance)
    if not target or not target.coords then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    if not coords then return false end

    return #(coords - target.coords) <= (maxDistance or 8.0)
end

----------------
--POLICE CHECK--
----------------

local cachedPoliceAmount = {}

QBCore.Functions.CreateCallback('mz-storerobbery:server:getCops', function(source, cb)
    local amount = 0
    for _, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if not Config.UsePoliceName then 
            if v.PlayerData.job.type == Config.PoliceJobType and v.PlayerData.job.onduty then
                amount = amount + 1
            end
        else 
            if v.PlayerData.job.name == Config.PoliceJobName and v.PlayerData.job.onduty then
                amount = amount + 1
            end
        end
    end
    cachedPoliceAmount[source] = amount
    cb(amount)
end)

-------------------
--SERVER LOCKOUTS--
-------------------

RegisterNetEvent('mz-storerobbery:server:setRegisterStatus', function(k)
    local src = source
    k = tonumber(k)

    local registers = getRegisterTable()
    local register = registers and registers[k]
    if not register or register.robbed or not isPlayerNearTarget(src, register, 8.0) then
        return
    end

    activeRegisterRobbers[k] = src
    register.robbed = true
    register.paidOut = false
    register.time = Config.resetTime

    if not Config.UseGabz then 
        TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, k, true)
        SetTimeout(Config.resetTime, function()
            Config.RegistersTarget[k].robbed = false
            Config.RegistersTarget[k].paidOut = false
            activeRegisterRobbers[k] = nil
            TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, k, false)
        end)
    else
        TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, k, true)
        SetTimeout(Config.resetTime, function()
            Config.RegistersTargetGabz[k].robbed = false
            Config.RegistersTargetGabz[k].paidOut = false
            activeRegisterRobbers[k] = nil
            TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, k, false)
        end) 
    end 
end)

RegisterNetEvent('mz-storerobbery:server:setRegisterStatusFailed', function(k)
    local src = source
    k = tonumber(k)
    if not k or activeRegisterRobbers[k] ~= src then return end
    activeRegisterRobbers[k] = nil

    if not Config.UseGabz then 
        if not Config.RegistersTarget[k] then return end
        Config.RegistersTarget[k].robbed = false
        Config.RegistersTarget[k].paidOut = false
        TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, k, false)
    else 
        if not Config.RegistersTargetGabz[k] then return end
        Config.RegistersTargetGabz[k].robbed = false
        Config.RegistersTargetGabz[k].paidOut = false
        TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, k, false)
    end
end)

RegisterNetEvent('mz-storerobbery:server:setSafeStatus', function(safe)
    local src = source
    safe = tonumber(safe)

    local safes = getSafeTable()
    local safeConfig = safes and safes[safe]
    if not safeConfig or safeConfig.robbed or not isPlayerNearTarget(src, safeConfig, 10.0) then
        return
    end

    activeSafeRobbers[safe] = src
    safeConfig.robbed = true
    safeConfig.paidOut = false

    if not Config.UseGabz then 
        TriggerClientEvent('mz-storerobbery:client:setSafeStatus', -1, safe, true)
        SetTimeout(Config.SafeResetTime, function()
            Config.SafesTarget[safe].robbed = false
            Config.SafesTarget[safe].paidOut = false
            activeSafeRobbers[safe] = nil
            TriggerClientEvent('mz-storerobbery:client:setSafeStatus', -1, safe, false)
        end)
    else 
        TriggerClientEvent('mz-storerobbery:client:setSafeStatus', -1, safe, true)
        SetTimeout(Config.SafeResetTime, function()
            Config.SafesTargetGabz[safe].robbed = false
            Config.SafesTargetGabz[safe].paidOut = false
            activeSafeRobbers[safe] = nil
            TriggerClientEvent('mz-storerobbery:client:setSafeStatus', -1, safe, false)
        end)
    end 
end)

RegisterNetEvent('mz-storerobbery:server:setSafeStatusFailed', function(safe)
    local src = source
    safe = tonumber(safe)
    if not safe or activeSafeRobbers[safe] ~= src then return end
    activeSafeRobbers[safe] = nil

    if not Config.UseGabz then
        if not Config.SafesTarget[safe] then return end
        Config.SafesTarget[safe].robbed = false
        Config.SafesTarget[safe].paidOut = false
        TriggerClientEvent('mz-storerobbery:client:setSafeStatus', -1, safe, false)
    else 
        if not Config.SafesTargetGabz[safe] then return end
        Config.SafesTargetGabz[safe].robbed = false
        Config.SafesTargetGabz[safe].paidOut = false
        TriggerClientEvent('mz-storerobbery:client:setSafeStatus', -1, safe, false)
    end 
end)

----------------
--LOOT REWARDS--
----------------

-- REGISTERS 

RegisterNetEvent('mz-storerobbery:server:takeMoney', function(register, isDone, registerDone)
    if not registerDone then 
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then 
            return 
        end

        register = tonumber(register)
        local registers = getRegisterTable()
        local registerConfig = registers and registers[register]
        if not isDone
            or not registerConfig
            or not registerConfig.robbed
            or registerConfig.paidOut
            or activeRegisterRobbers[register] ~= src
            or not isPlayerNearTarget(src, registerConfig, 8.0) then
            print("Rejected invalid mz-storerobbery register payout attempt from " .. tostring(src))
            return
        end

        registerConfig.paidOut = true
        activeRegisterRobbers[register] = nil

        if isDone then
            if Config.CashRegisterReturn == "dirtymoney" then 
                local amount = math.random(Config.minRegisterEarn, Config.maxRegisterEarn)
                Player.Functions.AddItem('dirtymoney', amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['dirtymoney'], "add", amount)
                if Config.NotifyType == 'qb' then
                    TriggerClientEvent('QBCore:Notify', src, "You stole $" ..amount.. " from the till!", 'success')
                elseif Config.NotifyType == "okok" then
                    TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE TILL", "You stole $" ..amount.. " from the till!", 4500, 'success')
                end
                Wait(1500)
                if math.random(1, 100) <= Config.liquorKey then 
                    Player.Functions.AddItem(Config.LiquorItem, 1)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorItem], "add", 1)
                end
            elseif Config.CashRegisterReturn == "markedbills" then 
                local info = {
                    worth = math.random(Config.minRegisterEarn, Config.maxRegisterEarn)
                }
                Player.Functions.AddItem('markedbills', 1, false, info)
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], "add")
                if Config.NotifyType == 'qb' then
                    TriggerClientEvent('QBCore:Notify', src, "You stole $" ..info.worth.. " from the till!", 'success')
                elseif Config.NotifyType == "okok" then
                    TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE TILL", "You stole $" ..info.worth.. " from the till!", 4500, 'success')
                end
                Wait(1500)
                if math.random(1, 100) <= Config.liquorKey then 
                    Player.Functions.AddItem(Config.LiquorItem, 1)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorItem], "add", 1)
                end
            elseif Config.CashRegisterReturn == "cash" then 
                local cleanmoney = math.random(Config.minRegisterEarn, Config.maxRegisterEarn)
                Player.Functions.AddMoney('cash', cleanmoney)
                if Config.NotifyType == 'qb' then
                    TriggerClientEvent('QBCore:Notify', src, "You stole $" ..cleanmoney.. " from the till!", 'success')
                elseif Config.NotifyType == "okok" then
                    TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE TILL", "You stole $" ..cleanmoney.. " from the till!", 4500, 'success')
                end
                if math.random(1, 100) <= Config.liquorKey then 
                    Player.Functions.AddItem(Config.LiquorItem, 1)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorItem], "add", 1)
                end
            else 
                print("You have not properly configured 'Config.CashRegisterReturn', please refer to config.lua")
            end
        end
    else 
        print("Someone is attempting to trigger 'mz-storerobbery:server:takeMoney' externally.")
    end
end)

-- CONVENIENCE STORES

RegisterNetEvent('mz-storerobbery:server:SafeReward', function(safe, safeCheck)
    if not safeCheck then 
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then 
            return 
        end

        safe = tonumber(safe)
        local safes = getSafeTable()
        local safeConfig = safes and safes[safe]
        if not safeConfig
            or not safeConfig.robbed
            or safeConfig.paidOut
            or activeSafeRobbers[safe] ~= src
            or not isPlayerNearTarget(src, safeConfig, 10.0) then
            print("Rejected invalid mz-storerobbery safe payout attempt from " .. tostring(src))
            return
        end

        safeConfig.paidOut = true
        activeSafeRobbers[safe] = nil

        if Config.SafeReturn == "dirtymoney" then 
            local amount = math.random(Config.minSafeEarn, Config.maxSafeEarn)
            Player.Functions.AddItem('dirtymoney', amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['dirtymoney'], "add", amount)
            if Config.NotifyType == 'qb' then
                TriggerClientEvent('QBCore:Notify', src, "You stole $" ..amount.. " from the safe!", 'success', 4500)
            elseif Config.NotifyType == "okok" then
                TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE SAFE", "You stole $" ..amount.. " from the safe!", 4500, 'success')
            end
            if math.random(1, 100) <= Config.liquorKeySafe then 
                Player.Functions.AddItem(Config.LiquorItem, 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorItem], "add", 1)
            end
            if Config.RareItemDrops then 
                if math.random(1, 100) <= Config.RareItem1Chance then 
                    Player.Functions.AddItem(Config.RareItem1, Config.RareItemAmount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem1], "add", Config.RareItemAmount)
                end
                if math.random(1, 100) <= Config.RareItem2Chance then 
                    Player.Functions.AddItem(Config.RareItem2, Config.RareItem2Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem2], "add", Config.RareItem2Amount)
                end
                if math.random(1, 100) <= Config.RareItem3Chance then 
                    Player.Functions.AddItem(Config.RareItem3, Config.RareItem3Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem3], "add", Config.RareItem3Amount)
                end
            end 
        elseif Config.SafeReturn == "markedbills" then
            local info = {
                worth = math.random(Config.minSafeEarn, Config.maxSafeEarn)
            }
            Player.Functions.AddItem('markedbills', 1, false, info)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], "add")
            if Config.NotifyType == 'qb' then
                TriggerClientEvent('QBCore:Notify', src, "You stole $" ..info.worth.. " from the safe!", 'success', 4500)
            elseif Config.NotifyType == "okok" then
                TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE SAFE", "You stole $" ..info.worth.. " from the safe!", 4500, 'success')
            end
            if math.random(1, 100) <= Config.liquorKeySafe then 
                Player.Functions.AddItem(Config.LiquorItem, 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorItem], "add", 1)
            end
            if Config.RareItemDrops then
                if math.random(1, 100) <= Config.RareItem1Chance then 
                    Player.Functions.AddItem(Config.RareItem1, Config.RareItemAmount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem1], "add", Config.RareItemAmount)
                end
                if math.random(1, 100) <= Config.RareItem2Chance then 
                    Player.Functions.AddItem(Config.RareItem2, Config.RareItem2Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem2], "add", Config.RareItem2Amount)
                end
                if math.random(1, 100) <= Config.RareItem3Chance then 
                    Player.Functions.AddItem(Config.RareItem3, Config.RareItem3Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem3], "add", Config.RareItem3Amount)
                end
            end
        elseif Config.SafeReturn == "cash" then
            local cleanmoney = math.random(Config.minSafeEarn, Config.maxSafeEarn)
            Player.Functions.AddMoney('cash', cleanmoney)
            if Config.NotifyType == 'qb' then
                TriggerClientEvent('QBCore:Notify', src, "You stole $" ..cleanmoney.. " from the safe!", 'success')
            elseif Config.NotifyType == "okok" then
                TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE TILL", "You stole $" ..cleanmoney.. " from the safe!", 4500, 'success')
            end
            if math.random(1, 100) <= Config.liquorKeySafe then 
                Player.Functions.AddItem(Config.LiquorItem, 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorItem], "add", 1)
            end
            if Config.RareItemDrops then
                if math.random(1, 100) <= Config.RareItem1Chance then 
                    Player.Functions.AddItem(Config.RareItem1, Config.RareItemAmount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem1], "add", Config.RareItemAmount)
                end
                if math.random(1, 100) <= Config.RareItem2Chance then 
                    Player.Functions.AddItem(Config.RareItem2, Config.RareItem2Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem2], "add", Config.RareItem2Amount)
                end
                if math.random(1, 100) <= Config.RareItem3Chance then 
                    Player.Functions.AddItem(Config.RareItem3, Config.RareItem3Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RareItem3], "add", Config.RareItem3Amount)
                end 
            end
        else
            print("You have not properly configured 'Config.SafeReturn', please refer to config.lua")
        end
    else 
        print("Someone is attempting to trigger 'mz-storerobbery:server:SafeReward' externally.")
    end
end)

-- LIQUOR STORES

RegisterNetEvent('mz-storerobbery:server:SafeRewardAlcohol', function(safe, safeCheck)
    if not safeCheck then 
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then 
            return 
        end

        safe = tonumber(safe)
        local safes = getSafeTable()
        local safeConfig = safes and safes[safe]
        if not safeConfig
            or not safeConfig.robbed
            or safeConfig.paidOut
            or activeSafeRobbers[safe] ~= src
            or not isPlayerNearTarget(src, safeConfig, 10.0) then
            print("Rejected invalid mz-storerobbery liquor safe payout attempt from " .. tostring(src))
            return
        end

        safeConfig.paidOut = true
        activeSafeRobbers[safe] = nil

        if Config.AlcoholReturn == "dirtymoney" then 
            local amount = math.random(Config.AlcoholminSafeEarn, Config.AlcoholmaxSafeEarn)
            Player.Functions.AddItem('dirtymoney', amount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['dirtymoney'], "add")
            if Config.NotifyType == 'qb' then
                TriggerClientEvent('QBCore:Notify', src, "You stole $" ..amount.. " from the safe!", 'success', 4500)
            elseif Config.NotifyType == "okok" then
                TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE SAFE", "You stole $" ..amount.. " from the safe!", 4500, 'success')
            end
            if Config.AlcoholRareItemDrops then 
                if math.random(1, 100) <= Config.AlcoholRareItem1Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem1, Config.AlcoholRareItemAmount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem1], "add", Config.AlcoholRareItemAmount)
                end
                if math.random(1, 100) <= Config.AlcoholRareItem2Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem2, Config.AlcoholRareItem2Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem2], "add", Config.AlcoholRareItem2Amount)
                end
                if math.random(1, 100) <= Config.AlcoholRareItem3Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem3, Config.AlcoholRareItem3Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem3], "add", Config.AlcoholRareItem3Amount)
                end
            end 
        elseif Config.AlcoholReturn == "markedbills" then 
            local info = {
                worth = math.random(Config.AlcoholminSafeEarn, Config.AlcoholmaxSafeEarn)
            }
            Player.Functions.AddItem('markedbills', 1, false, info)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], "add")
            if Config.NotifyType == 'qb' then
                TriggerClientEvent('QBCore:Notify', src, "You stole $" ..info.worth.. " from the safe!", 'success', 4500)
            elseif Config.NotifyType == "okok" then
                TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE SAFE", "You stole $" ..info.worth.. " from the safe!", 4500, 'success')
            end
            if Config.AlcoholRareItemDrops then
                if math.random(1, 100) <= Config.AlcoholRareItem1Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem1, Config.AlcoholRareItemAmount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem1], "add", Config.AlcoholRareItemAmount)
                end
                if math.random(1, 100) <= Config.AlcoholRareItem2Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem2, Config.AlcoholRareItem2Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem2], "add", Config.AlcoholRareItem2Amount)
                end
                if math.random(1, 100) <= Config.AlcoholRareItem3Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem3, Config.AlcoholRareItem3Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem3], "add", Config.AlcoholRareItem3Amount)
                end
            end 
        elseif Config.AlcoholReturn == "cash" then 
            local cleanmoney = math.random(Config.AlcoholminSafeEarn, Config.AlcoholmaxSafeEarn)
            Player.Functions.AddMoney('cash', cleanmoney)
            if Config.NotifyType == 'qb' then
                TriggerClientEvent('QBCore:Notify', src, "You stole $" ..cleanmoney.. " from the safe!", 'success')
            elseif Config.NotifyType == "okok" then
                TriggerClientEvent('okokNotify:Alert', source, "RAIDED THE TILL", "You stole $" ..cleanmoney.. " from the safe!", 4500, 'success')
            end
            if Config.AlcoholRareItemDrops then
                if math.random(1, 100) <= Config.AlcoholRareItem1Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem1, Config.AlcoholRareItemAmount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem1], "add", Config.AlcoholRareItemAmount)
                end
                if math.random(1, 100) <= Config.AlcoholRareItem2Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem2, Config.AlcoholRareItem2Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem2], "add", Config.AlcoholRareItem2Amount)
                end
                if math.random(1, 100) <= Config.AlcoholRareItem3Chance then 
                    Player.Functions.AddItem(Config.AlcoholRareItem3, Config.AlcoholRareItem3Amount, false)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.AlcoholRareItem3], "add", Config.AlcoholRareItem3Amount)
                end
            end
        else
            print("You have not properly configured 'Config.AlcoholReturn', please refer to config.lua")
        end
    else 
        print("Someone is attempting to trigger 'mz-storerobbery:server:SafeRewardAlcohol' externally.")
    end
end)

----------------
--ITEM REMOVAL--
----------------

RegisterServerEvent('mz-storerobbery:server:ItemRemoval', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(Config.SafeReqItem, 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.SafeReqItem], "remove", 1)
end)

RegisterServerEvent('mz-storerobbery:server:ItemRemovalLiquor', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(Config.LiquorReqItem, 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LiquorReqItem], "remove", 1)
end)

RegisterServerEvent('mz-storerobbery:server:RemoveLockpick', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem('lockpick', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['lockpick'], "remove", 1)
end)

RegisterServerEvent('mz-storerobbery:server:RemoveAdvanced', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem('advancedlockpick', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['advancedlockpick'], "remove", 1)
end)

RegisterServerEvent('mz-storerobbery:server:SafeFail', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Config.NotifyType == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, "You failed to infiltrate the safe...", 'error', 3500)
    elseif Config.NotifyType == "okok" then
        TriggerClientEvent('okokNotify:Alert', source, "WASTED USB", "You failed to infiltrate the safe...", 3500, 'error')
    end
end)

RegisterServerEvent('mz-storerobbery:server:KeyRemoval', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem('liquorkey', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['liquorkey'], "remove", 1)
    if Config.NotifyType == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, "You broke the key... Well done...", 'error')
    elseif Config.NotifyType == "okok" then
        TriggerClientEvent('okokNotify:Alert', source, "KEY BROKE", "You broke the key... Well done...", 4500, 'error')
    end
end)

-------------
--FUNCTIONS--
-------------

RegisterNetEvent('mz-storerobbery:server:callCops', function(type, safe, streetLabel, coords)
    local cameraId
    if type == "safe" then
        if Config.UseGabz then
            cameraId = Config.SafesTarget[safe].camId
        else 
            cameraId = Config.SafesTargetGabz[safe].camId
        end 
    else
        if not Config.UseGabz then 
            cameraId = Config.RegistersTarget[safe].camId
        else 
            cameraId = Config.RegistersTargetGabz[safe].camId
        end 
    end
    local alertData = {
        title = "10-33 | Shop Robbery",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = "Someone Is Trying To Rob A Store At "..streetLabel.." (CAMERA ID: "..cameraId..")"
    }
    TriggerClientEvent("mz-storerobbery:client:robberyCall", -1, type, safe, streetLabel, coords)
    TriggerEvent('police:server:policeAlert', alertData.description, cameraId, source)
end)

CreateThread(function()
    while true do
        local toSend = {}
        if not Config.UseGabz then 
            for k in ipairs(Config.RegistersTarget) do
                if Config.RegistersTarget[k].time > 0 and (Config.RegistersTarget[k].time - Config.tickInterval) >= 0 then
                    Config.RegistersTarget[k].time = Config.RegistersTarget[k].time - Config.tickInterval
                else
                    if Config.RegistersTarget[k].robbed then
                        Config.RegistersTarget[k].time = 0
                        Config.RegistersTarget[k].robbed = false
                        Config.RegistersTarget[k].paidOut = false
                        activeRegisterRobbers[k] = nil
                        toSend[#toSend+1] = Config.RegistersTarget[k]
                    end
                end
            end
        else 
            for k in ipairs(Config.RegistersTargetGabz) do
                if Config.RegistersTargetGabz[k].time > 0 and (Config.RegistersTargetGabz[k].time - Config.tickInterval) >= 0 then
                    Config.RegistersTargetGabz[k].time = Config.RegistersTargetGabz[k].time - Config.tickInterval
                else
                    if Config.RegistersTargetGabz[k].robbed then
                        Config.RegistersTargetGabz[k].time = 0
                        Config.RegistersTargetGabz[k].robbed = false
                        Config.RegistersTargetGabz[k].paidOut = false
                        activeRegisterRobbers[k] = nil
                        toSend[#toSend+1] = Config.RegistersTargetGabz[k]
                    end
                end
            end
        end 
        if #toSend > 0 then
            TriggerClientEvent('mz-storerobbery:client:setRegisterStatus', -1, toSend, false)
        end
        Wait(Config.tickInterval)
    end
end)

QBCore.Functions.CreateCallback('mz-storerobbery:server:getPadlockCombination', function(_, cb, safe)
    cb(SafeCodes[safe])
end)

QBCore.Functions.CreateCallback('mz-storerobbery:server:getRegisterStatus', function(_, cb)
    if not Config.UseGabz then 
        cb(Config.RegistersTarget)
    else 
        cb(Config.RegistersTargetGabz)
    end 
end)

QBCore.Functions.CreateCallback('mz-storerobbery:server:getSafeStatus', function(_, cb)
    if not Config.UseGabz then 
        cb(Config.SafesTarget)
    else 
        cb(Config.SafesTargetGabz)
    end 
end)