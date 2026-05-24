-- cool down for job
RegisterServerEvent('dr-ammorobbery:sv:coolout', function()
    Cooldown = true
    local timer = Config.Cooldown * 60000
    while timer > 0 do
        Wait(1000)
        timer = timer - 1000
        if timer == 0 then
            Cooldown = false
            TriggerClientEvent("dr-ammorobbery:cl:clear", -1)
        end
    end
end)

lib.callback.register('dr-ammorobbery:sv:coolc', function()
    return Cooldown == true
end)

lib.callback.register('dr-ammorobbery:sv:GetCops', function()
    local amount = 0
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src then
            local p = exports.qbx_core:GetPlayer(src)
            local job = p and p.PlayerData and p.PlayerData.job
            if job and job.type == Config.PoliceJobtype and job.onduty then
                amount += 1
            end
        end
    end
    return amount
end)


RegisterServerEvent('dr-ammorobbery:sv:containerSync')
AddEventHandler('dr-ammorobbery:sv:containerSync', function(coords, rotation, index)
    TriggerClientEvent('dr-ammorobbery:cl:containerSync', -1, coords, rotation, index)
end)

RegisterServerEvent('dr-ammorobbery:sv:lockSync')
AddEventHandler('dr-ammorobbery:sv:lockSync', function(index)
    TriggerClientEvent('dr-ammorobbery:cl:lockSync', -1, index)
end)

RegisterServerEvent('dr-ammorobbery:sv:objectSync')
AddEventHandler('dr-ammorobbery:sv:objectSync', function(e)
    TriggerClientEvent('dr-ammorobbery:cl:objectSync', -1, e)
end)

RegisterServerEvent('dr-ammorobbery:sv:synctarget')
AddEventHandler('dr-ammorobbery:sv:synctarget', function()
    TriggerClientEvent('dr-ammorobbery:cl:targetsync', -1)
    local index = math.random(1, #Config.Items)
    local stashName = "WeaponCrate"
    local newItems = Config.Items[index]
    AddItemsToStash(stashName, newItems)
end)

RegisterNetEvent('Jommidar-ammorobbery:AddItem', function(itemName, itemAmount)
    local src = source
    if GetResourceState('ox_inventory') ~= 'started' then return end
    itemName = tostring(itemName or '')
    itemAmount = math.floor(tonumber(itemAmount) or 0)
    if itemName == '' or itemAmount <= 0 then return end
    exports.ox_inventory:AddItem(src, itemName, itemAmount)
end)

RegisterServerEvent('dr-ammorobbery:sv:ClearSync')
AddEventHandler('dr-ammorobbery:sv:ClearSync', function()
    TriggerClientEvent("dr-ammorobbery:cl:clear", -1)
end)

-- Function to add multiple items to the stash in the corresponding row of the database table
function AddItemsToStash(stashName, newItems)
    -- Convert the list of new items into a JSON string
    local newItemsJSON = json.encode(newItems)

    -- SQL query to update the 'items' column in the row with the name 'WeaponCrate'
    local query = "UPDATE stashitems SET items = JSON_MERGE_PATCH(items, '" .. newItemsJSON .. "') WHERE stash = '" .. stashName .. "'"

    -- Execute the query asynchronously
    MySQL.Async.execute(query, {}, function(rowsChanged)
        if rowsChanged > 0 then
            print("Items added to stash successfully!")
        else
            print("Failed to add items to stash.")
        end
    end)
end

if Config.CheckForUpdates then
    local function VersionLog(_type, log)
        local color = _type == 'success' and '^2' or '^1'
        print(('^8[Dracula]%s %s^7'):format(color, log))
    end

    local function UpdateLog(log)
        print(('^8[Dracula]^3 [Update Log] %s^7'):format(log))
    end

    local function FetchUpdateLog()
        PerformHttpRequest('https://raw.githubusercontent.com/Haaasib/updates/main/ar.txt', function(err, text, headers)
            if not text then
                UpdateLog('Currently unable to fetch the update log.')
                return
            end
            UpdateLog(':\n' .. text)
        end)
    end

    local function CheckMenuVersion()
        PerformHttpRequest('https://raw.githubusercontent.com/Haaasib/updates/main/ammorob.txt', function(err, text, headers)
            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
            if not text then
                VersionLog('error', 'Currently unable to run a version check.')
                return
            end
            VersionLog('success', ('Current Version: %s'):format(currentVersion))
            VersionLog('success', ('Latest Version: %s'):format(text))
            if text:gsub("%s+", "") == currentVersion:gsub("%s+", "") then
                VersionLog('success', 'You are running the latest version.')
            else
                VersionLog('error', ('You are currently running an outdated version, please update to version %s'):format(text))
                FetchUpdateLog()
            end
        end)
    end

    CheckMenuVersion()
end


