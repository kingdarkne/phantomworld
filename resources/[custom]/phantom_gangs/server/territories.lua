-- Phantom Gangs - Territory Server Logic
local territoryOwners = {}
local territoryCooldowns = {}
local territoryIncomes = {}

-- Initialize territories
CreateThread(function()
    Wait(2000)

    -- Load territory ownership from DB
    local dbTerritories = MySQL.query.await('SELECT * FROM phantom_gang_territories')
    if dbTerritories then
        for _, t in ipairs(dbTerritories) do
            territoryOwners[t.territory_id] = {
                gangId = t.gang_id,
                capturedAt = t.captured_at,
            }
        end
    end

    -- Start income loop
    StartIncomeLoop()
end)

-- Can capture check
lib.callback.register('phantom_gangs:server:canCapture', function(source, territoryId)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end

    local gangId = GetPlayerGangId(Player.PlayerData.citizenid)
    if not gangId then return false end

    -- Check cooldown
    if territoryCooldowns[territoryId] and territoryCooldowns[territoryId] > os.time() then
        return false
    end

    -- Check if already owned by same gang
    local owner = territoryOwners[territoryId]
    if owner and owner.gangId == gangId then
        return false
    end

    return true
end)

-- Capture territory
RegisterNetEvent('phantom_gangs:server:captureTerritory', function(territoryId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local gangId = GetPlayerGangId(Player.PlayerData.citizenid)
    if not gangId then return end

    local gang = gangs[gangId]
    if not gang then return end

    -- Get territory config
    local territoryConfig = nil
    for _, t in ipairs(Config.Territories) do
        if t.id == territoryId then
            territoryConfig = t
            break
        end
    end
    if not territoryConfig then return end

    -- Set cooldown
    territoryCooldowns[territoryId] = os.time() + 600 -- 10 min cooldown

    -- Transfer ownership
    local oldOwner = territoryOwners[territoryId]
    territoryOwners[territoryId] = {
        gangId = gangId,
        capturedAt = os.time(),
    }

    -- Update gang territories
    if oldOwner and oldOwner.gangId then
        local oldGang = gangs[oldOwner.gangId]
        if oldGang then
            oldGang.territories[territoryId] = nil
        end
    end
    gang.territories[territoryId] = true

    -- Save to DB
    MySQL.insert('INSERT INTO phantom_gang_territories (territory_id, gang_id, captured_at) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE gang_id = ?, captured_at = ?', {
        territoryId, gangId, os.time(), gangId, os.time()
    })

    -- Notify
    local colorData = Config.GangColors[gang.color] or Config.GangColors.default
    TriggerClientEvent('phantom_gangs:client:territoryCaptured', -1, {
        territory = territoryConfig.name,
        gang = gang.name,
        color = gang.color,
    })

    -- Update all clients
    SyncTerritories()

    print('^2[Phantom Gangs]^7 ' .. gang.name .. ' captured ' .. territoryConfig.name)
end)

-- Get all territories
lib.callback.register('phantom_gangs:server:getAllTerritories', function(source)
    local result = {}
    for _, t in ipairs(Config.Territories) do
        local owner = territoryOwners[t.id]
        local ownerName = nil
        if owner and owner.gangId and gangs[owner.gangId] then
            ownerName = gangs[owner.gangId].name
        end
        table.insert(result, {
            id = t.id,
            name = t.name,
            type = t.type,
            income = t.income,
            owner = ownerName,
        })
    end
    return result
end)

-- Request territory sync
RegisterNetEvent('phantom_gangs:server:requestTerritoryData', function()
    SyncTerritories()
end)

-- Sync territories to all clients
function SyncTerritories()
    local syncData = {}
    for _, t in ipairs(Config.Territories) do
        local owner = territoryOwners[t.id]
        local gangColor = nil
        if owner and owner.gangId and gangs[owner.gangId] then
            gangColor = gangs[owner.gangId].color
        end
        syncData[t.id] = {
            owner = owner and owner.gangId and gangs[owner.gangId] and gangs[owner.gangId].name or nil,
            color = gangColor,
        }
    end
    TriggerClientEvent('phantom_gangs:client:updateTerritories', -1, syncData)
end

-- Income loop
function StartIncomeLoop()
    CreateThread(function()
        while true do
            Wait(Config.IncomeInterval * 60 * 1000)

            for territoryId, owner in pairs(territoryOwners) do
                if owner.gangId and gangs[owner.gangId] then
                    local gang = gangs[owner.gangId]
                    local territoryConfig = nil
                    for _, t in ipairs(Config.Territories) do
                        if t.id == territoryId then
                            territoryConfig = t
                            break
                        end
                    end

                    if territoryConfig then
                        -- Pay gang members
                        local income = territoryConfig.income
                        local share = math.floor(income / #gang.members)

                        for _, member in ipairs(gang.members) do
                            local memberPlayer = GetPlayerFromCitizenId(member.citizenid)
                            if memberPlayer then
                                local p = exports.qbx_core:GetPlayer(memberPlayer)
                                if p then
                                    p.Functions.AddMoney('bank', share, 'gang-territory-income')
                                end
                            end
                        end

                        print('^2[Phantom Gangs]^7 Paid $' .. share .. ' to each ' .. gang.name .. ' member from ' .. territoryConfig.name)
                    end
                end
            end
        end
    end)
end

-- Helper: Get player source from citizenid
function GetPlayerFromCitizenId(citizenid)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local p = exports.qbx_core:GetPlayer(tonumber(playerId))
        if p and p.PlayerData.citizenid == citizenid then
            return tonumber(playerId)
        end
    end
    return nil
end

-- Helper: Get player gang ID
function GetPlayerGangId(citizenid)
    return playerGangs[citizenid]
end

-- DB init
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_gang_territories (
                id INT AUTO_INCREMENT PRIMARY KEY,
                territory_id VARCHAR(50) NOT NULL UNIQUE,
                gang_id VARCHAR(50),
                captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_gang (gang_id)
            )
        ]])
    end
end)
