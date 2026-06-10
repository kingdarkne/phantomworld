local hasPhone = false

local function inventorySearchCount(searchType, items)
    if GetResourceState('ox_inventory') ~= 'started' then
        return nil
    end

    local ok, result = pcall(function()
        return exports.ox_inventory:Search(searchType, items)
    end)

    if not ok then
        return nil
    end

    return result
end

local function doPhoneCheck(isUnload, totalCount)
    hasPhone = false

    if isUnload then
        exports.npwd:setPhoneDisabled(true)
        return
    end

    if totalCount then
        hasPhone = totalCount > 0
        exports.npwd:setPhoneDisabled(not hasPhone)
        return
    end

    local items = inventorySearchCount('count', PhoneList)
    if items == nil then
        return
    end

    if type(items) == 'number' then
        hasPhone = items > 0
    else
        for _, v in pairs(items) do
            if v > 0 then
                hasPhone = true
                break
            end
        end
    end

    exports.npwd:setPhoneDisabled(not hasPhone)
end

exports("HasPhone", function()
    return hasPhone
end)

-- Handles state right when the player selects their character and location.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        for _ = 1, 40 do
            if GetResourceState('ox_inventory') == 'started' and inventorySearchCount('count', PhoneList) ~= nil then
                doPhoneCheck()
                return
            end
            Wait(250)
        end
        doPhoneCheck()
    end)
end)

-- Resets state on logout, in case of character change.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    doPhoneCheck(true)
    TriggerServerEvent('qbx_npwd:server:UnloadPlayer')
end)

AddEventHandler('ox_inventory:itemCount', function(itemName, totalCount)
    for i = 1, #PhoneList do
        if PhoneList[i] == itemName then
            doPhoneCheck(false, totalCount)
            break
        end
    end
end)

-- Handles state if resource is restarted live.
AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or GetResourceState('npwd') ~= 'started' then return end

    doPhoneCheck()
end)

-- Allows use of phone as an item.
RegisterNetEvent('qbx_npwd:client:setPhoneVisible', function(isPhoneVisible)
    exports.npwd:setPhoneVisible(isPhoneVisible)
end)