-- Phantom Gangs - Main Client
local QBCore = exports['qbx_core']:GetCoreObject()
local PlayerGang = nil
local inGangMenu = false
local territoryBlips = {}
local zoneBlips = {}
local inWar = false
local warScore = { friendly = 0, enemy = 0 }

-- Initialize
CreateThread(function()
    Wait(2000)
    CreateTerritoryBlips()
    print('^2[Phantom Gangs]^7 Client initialized')
end)

-- Create blips for territories
function CreateTerritoryBlips()
    for _, territory in ipairs(Config.Territories) do
        local blip = AddBlipForRadius(territory.coords.x, territory.coords.y, territory.coords.z, territory.radius)
        SetBlipColour(blip, 39) -- Light grey for neutral
        SetBlipAlpha(blip, 80)
        SetBlipAsShortRange(blip, false)
        territoryBlips[territory.id] = blip
    end
end

-- Update territory blip colors based on ownership
RegisterNetEvent('phantom_gangs:client:updateTerritories', function(territoryData)
    for territoryId, data in pairs(territoryData) do
        local blip = territoryBlips[territoryId]
        if blip then
            local color = 39 -- Neutral grey
            if data.owner then
                local gangColor = data.color or 'default'
                local colorMap = {
                    default = 2, green = 2, blue = 3, purple = 27,
                    orange = 51, yellow = 46, white = 0, black = 37
                }
                color = colorMap[gangColor] or 2
            end
            SetBlipColour(blip, color)

            -- Update center blip too
            if zoneBlips[territoryId] then
                RemoveBlip(zoneBlips[territoryId])
            end

            local territory = nil
            for _, t in ipairs(Config.Territories) do
                if t.id == territoryId then territory = t break end
            end
            if territory then
                local zBlip = AddBlipForCoord(territory.coords.x, territory.coords.y, territory.coords.z)
                SetBlipSprite(zBlip, 310)
                SetBlipColour(zBlip, color)
                SetBlipScale(zBlip, 0.8)
                SetBlipAsShortRange(zBlip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName((data.owner and '[' .. data.owner .. '] ' or '') .. territory.name)
                EndTextCommandSetBlipName(zBlip)
                zoneBlips[territoryId] = zBlip
            end
        end
    end
end)

-- Request territory data on join
CreateThread(function()
    Wait(5000)
    TriggerServerEvent('phantom_gangs:server:requestTerritoryData')
end)

-- Main thread - check territory proximity and draw zones
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, territory in ipairs(Config.Territories) do
            local dist = #(coords - territory.coords)
            if dist < territory.radius + 50.0 then
                DrawTerritoryZone(territory)
            end
        end
    end
end)

-- Draw territory zone markers
function DrawTerritoryZone(territory)
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < 1000 do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - territory.coords)

            if dist < territory.radius then
                -- Draw zone boundary
                DrawMarker(28, territory.coords.x, territory.coords.y, territory.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, territory.radius * 2, territory.radius * 2, 50.0, 255, 0, 0, 40, false, false, 2, false, nil, nil, false)

                -- Show territory info
                if dist < 20.0 then
                    Draw3DText(territory.coords + vec3(0, 0, 5.0), '~r~' .. territory.name .. '~w~\nType: ' .. territory.type:upper() .. '\nIncome: $' .. territory.income .. '/hr', 0.4, 4)
                end

                -- Capture prompt
                if dist < 5.0 and not inWar then
                    local isGangMember = PlayerGang ~= nil
                    if isGangMember then
                        Draw3DText(coords + vec3(0, 0, 1.0), '~r~[E]~w~ Capture Territory', 0.35, 4)
                        if IsControlJustPressed(0, 38) then
                            AttemptCapture(territory)
                        end
                    end
                end
            end
        end
    end)
end

-- Attempt territory capture
function AttemptCapture(territory)
    local canCapture = lib.callback.await('phantom_gangs:server:canCapture', false, territory.id)
    if not canCapture then
        lib.notify({ title = 'Cannot Capture', description = 'Cooldown active or not enough members', type = 'error' })
        return
    end

    -- Start capture progress
    local success = lib.progressBar({
        duration = territory.captureTime * 1000,
        label = 'Capturing ' .. territory.name .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = false, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_player' }
    })

    if success then
        TriggerServerEvent('phantom_gangs:server:captureTerritory', territory.id)
    end
end

-- Gang menu command
RegisterCommand('gangmenu', function()
    OpenGangMenu()
end)

RegisterKeyMapping('gangmenu', 'Open Gang Menu', 'keyboard', 'F7')

-- Open gang menu
function OpenGangMenu()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local gangData = lib.callback.await('phantom_gangs:server:getPlayerGang', false)

    if not gangData then
        -- Not in a gang - show creation/join options
        local options = {
            {
                title = 'Create Gang',
                description = 'Cost: $' .. Config.GangCreation.cost,
                onSelect = function()
                    CreateGangDialog()
                end
            },
            {
                title = 'View Territories',
                description = 'See all territory info',
                onSelect = function()
                    ViewTerritoriesMenu()
                end
            }
        }
        lib.registerContext({ id = 'gang_menu_no_gang', title = 'Gang Menu', options = options })
        lib.showContext('gang_menu_no_gang')
        return
    end

    PlayerGang = gangData

    local options = {
        { title = 'Gang: ' .. gangData.name, description = 'Rank: ' .. gangData.rank, disabled = true },
        { title = 'Territories', description = 'View captured territories', onSelect = function() ViewTerritoriesMenu() end },
        { title = 'Members', description = 'Manage gang members', onSelect = function() ViewMembersMenu() end },
        { title = 'Start War', description = 'Declare war on another gang', onSelect = function() StartWarMenu() end },
        { title = 'Leave Gang', description = 'Leave your current gang', onSelect = function() LeaveGang() end },
    }

    lib.registerContext({ id = 'gang_menu', title = 'Gang Menu - ' .. gangData.name, options = options })
    lib.showContext('gang_menu')
end

-- Create gang dialog
function CreateGangDialog()
    local input = lib.inputDialog('Create Gang', {
        { type = 'input', label = 'Gang Name', required = true, min = 3, max = 20 },
        { type = 'select', label = 'Gang Color', required = true, options = {
            { value = 'green', label = 'Green' },
            { value = 'blue', label = 'Blue' },
            { value = 'purple', label = 'Purple' },
            { value = 'orange', label = 'Orange' },
            { value = 'yellow', label = 'Yellow' },
            { value = 'white', label = 'White' },
            { value = 'black', label = 'Black' },
        }},
        { type = 'input', label = 'Tag/Initials (3 chars)', required = true, min = 2, max = 4 },
    })

    if not input then return end

    local result = lib.callback.await('phantom_gangs:server:createGang', false, {
        name = input[1],
        color = input[2],
        tag = input[3]:upper()
    })

    if result.success then
        lib.notify({ title = 'Gang Created!', description = input[1] .. ' has been founded!', type = 'success' })
    else
        lib.notify({ title = 'Failed', description = result.message or 'Could not create gang', type = 'error' })
    end
end

-- View territories
function ViewTerritoriesMenu()
    local territories = lib.callback.await('phantom_gangs:server:getAllTerritories', false)
    local options = {}

    for _, t in ipairs(territories) do
        local ownerText = t.owner and ('Owner: ' .. t.owner) or 'Unclaimed'
        table.insert(options, {
            title = t.name,
            description = ownerText .. ' | Income: $' .. t.income .. '/hr',
            disabled = true
        })
    end

    lib.registerContext({ id = 'territory_list', title = 'Territories', options = options })
    lib.showContext('territory_list')
end

-- View members
function ViewMembersMenu()
    if not PlayerGang then return end
    local members = lib.callback.await('phantom_gangs:server:getGangMembers', false, PlayerGang.id)
    local options = {}

    for _, member in ipairs(members) do
        table.insert(options, {
            title = member.name,
            description = 'Rank: ' .. member.rank,
            disabled = true
        })
    end

    lib.registerContext({ id = 'gang_members', title = 'Gang Members', options = options })
    lib.showContext('gang_members')
end

-- Start war menu
function StartWarMenu()
    if not PlayerGang then return end
    local gangs = lib.callback.await('phantom_gangs:server:getRivalGangs', false, PlayerGang.id)
    local options = {}

    for _, gang in ipairs(gangs) do
        table.insert(options, {
            title = gang.name,
            description = 'Territories: ' .. (gang.territoryCount or 0),
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Declare War',
                    content = 'Declare war on ' .. gang.name .. '?\nWar lasts 10 minutes.',
                    cancel = true
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('phantom_gangs:server:declareWar', PlayerGang.id, gang.id)
                end
            end
        })
    end

    lib.registerContext({ id = 'war_declare', title = 'Declare War', options = options })
    lib.showContext('war_declare')
end

-- Leave gang
function LeaveGang()
    if not PlayerGang then return end
    local confirm = lib.alertDialog({
        header = 'Leave Gang',
        content = 'Leave ' .. PlayerGang.name .. '?',
        cancel = true
    })
    if confirm == 'confirm' then
        TriggerServerEvent('phantom_gangs:server:leaveGang')
        PlayerGang = nil
    end
end

-- War notifications
RegisterNetEvent('phantom_gangs:client:warStarted', function(data)
    inWar = true
    warScore = { friendly = 0, enemy = 0 }
    lib.notify({
        title = '⚔️ GANG WAR STARTED!',
        description = data.attacker .. ' vs ' .. data.defender .. '\nDuration: 10 minutes',
        type = 'error',
        duration = 10000
    })
end)

RegisterNetEvent('phantom_gangs:client:warEnded', function(data)
    inWar = false
    local winnerText = data.winner and (data.winner .. ' WINS!') or 'DRAW'
    lib.notify({
        title = '⚔️ GANG WAR ENDED',
        description = winnerText .. '\nFinal Score: ' .. data.score,
        type = data.winner == PlayerGang?.name and 'success' or 'info',
        duration = 10000
    })
end)

RegisterNetEvent('phantom_gangs:client:warScoreUpdate', function(score)
    warScore = score
end)

-- Territory captured notification
RegisterNetEvent('phantom_gangs:client:territoryCaptured', function(data)
    lib.notify({
        title = '🏴‍☠️ Territory Captured!',
        description = data.gang .. ' captured ' .. data.territory,
        type = 'success',
        duration = 8000
    })
end)

-- 3D text helper
function Draw3DText(coords, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

print('^2[Phantom Gangs]^7 Client loaded')
