-- Phantom Gangs - Server Main
local gangs = {}
local playerGangs = {}
local gangWars = {}

-- Create gang
lib.callback.register('phantom_gangs:server:createGang', function(source, data)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { success = false, message = 'Player not found' } end

    -- Check if already in gang
    for _, gang in pairs(gangs) do
        for _, member in ipairs(gang.members) do
            if member.citizenid == Player.PlayerData.citizenid then
                return { success = false, message = 'Already in a gang' }
            end
        end
    end

    -- Check cost
    if Player.PlayerData.money.cash < Config.GangCreation.cost then
        return { success = false, message = 'Need $' .. Config.GangCreation.cost }
    end

    -- Check max gangs
    if TableLength(gangs) >= Config.GangCreation.maxGangs then
        return { success = false, message = 'Max gangs reached (' .. Config.GangCreation.maxGangs .. ')' }
    end

    -- Deduct cost
    Player.Functions.RemoveMoney('cash', Config.GangCreation.cost, 'gang-creation')

    -- Create gang
    local gangId = 'gang_' .. os.time() .. '_' .. math.random(1000, 9999)
    gangs[gangId] = {
        id = gangId,
        name = data.name,
        color = data.color,
        tag = data.tag,
        owner = Player.PlayerData.citizenid,
        members = {
            {
                citizenid = Player.PlayerData.citizenid,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                rank = 'Boss',
                rankId = 5,
            }
        },
        territories = {},
        createdAt = os.time(),
        warsWon = 0,
        warsLost = 0,
    }

    playerGangs[Player.PlayerData.citizenid] = gangId

    -- Save to DB
    MySQL.insert('INSERT INTO phantom_gangs (gang_id, name, color, tag, owner, created_at) VALUES (?, ?, ?, ?, ?, ?)', {
        gangId, data.name, data.color, data.tag, Player.PlayerData.citizenid, os.time()
    })

    MySQL.insert('INSERT INTO phantom_gang_members (gang_id, citizenid, name, rank, rank_id, joined_at) VALUES (?, ?, ?, ?, ?, ?)', {
        gangId, Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, 'Boss', 5, os.time()
    })

    return { success = true, gang = gangs[gangId] }
end)

-- Get player's gang
lib.callback.register('phantom_gangs:server:getPlayerGang', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return nil end

    local gangId = playerGangs[Player.PlayerData.citizenid]
    if not gangId then return nil end

    local gang = gangs[gangId]
    if not gang then return nil end

    -- Find member data
    for _, member in ipairs(gang.members) do
        if member.citizenid == Player.PlayerData.citizenid then
            return {
                id = gang.id,
                name = gang.name,
                color = gang.color,
                tag = gang.tag,
                rank = member.rank,
                rankId = member.rankId,
            }
        end
    end
    return nil
end)

-- Get gang members
lib.callback.register('phantom_gangs:server:getGangMembers', function(source, gangId)
    local gang = gangs[gangId]
    if not gang then return {} end
    return gang.members
end)

-- Get rival gangs
lib.callback.register('phantom_gangs:server:getRivalGangs', function(source, myGangId)
    local rivals = {}
    for id, gang in pairs(gangs) do
        if id ~= myGangId then
            table.insert(rivals, {
                id = gang.id,
                name = gang.name,
                color = gang.color,
                territoryCount = TableLength(gang.territories)
            })
        end
    end
    return rivals
end)

-- Leave gang
RegisterNetEvent('phantom_gangs:server:leaveGang', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local gangId = playerGangs[Player.PlayerData.citizenid]
    if not gangId then return end

    local gang = gangs[gangId]
    if not gang then return end

    -- Remove from members
    for i, member in ipairs(gang.members) do
        if member.citizenid == Player.PlayerData.citizenid then
            table.remove(gang.members, i)
            break
        end
    end

    playerGangs[Player.PlayerData.citizenid] = nil

    -- If no members left, disband
    if #gang.members == 0 then
        gangs[gangId] = nil
        MySQL.update('DELETE FROM phantom_gangs WHERE gang_id = ?', { gangId })
    end

    MySQL.update('DELETE FROM phantom_gang_members WHERE citizenid = ?', { Player.PlayerData.citizenid })

    TriggerClientEvent('ox_lib:notify', src, { title = 'Left Gang', type = 'info' })
end)

-- Load gangs from DB on start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_gangs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                gang_id VARCHAR(50) NOT NULL UNIQUE,
                name VARCHAR(100) NOT NULL,
                color VARCHAR(50),
                tag VARCHAR(10),
                owner VARCHAR(50),
                wars_won INT DEFAULT 0,
                wars_lost INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_gang_members (
                id INT AUTO_INCREMENT PRIMARY KEY,
                gang_id VARCHAR(50) NOT NULL,
                citizenid VARCHAR(50) NOT NULL,
                name VARCHAR(100),
                rank VARCHAR(50),
                rank_id INT DEFAULT 1,
                joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_gang (gang_id),
                INDEX idx_citizenid (citizenid)
            )
        ]])

        -- Load existing gangs
        local dbGangs = MySQL.query.await('SELECT * FROM phantom_gangs')
        if dbGangs then
            for _, dbGang in ipairs(dbGangs) do
                gangs[dbGang.gang_id] = {
                    id = dbGang.gang_id,
                    name = dbGang.name,
                    color = dbGang.color,
                    tag = dbGang.tag,
                    owner = dbGang.owner,
                    members = {},
                    territories = {},
                    createdAt = dbGang.created_at,
                    warsWon = dbGang.wars_won,
                    warsLost = dbGang.wars_lost,
                }
            end

            -- Load members
            local dbMembers = MySQL.query.await('SELECT * FROM phantom_gang_members')
            if dbMembers then
                for _, member in ipairs(dbMembers) do
                    local gang = gangs[member.gang_id]
                    if gang then
                        table.insert(gang.members, {
                            citizenid = member.citizenid,
                            name = member.name,
                            rank = member.rank,
                            rankId = member.rank_id,
                        })
                        playerGangs[member.citizenid] = member.gang_id
                    end
                end
            end
        end

        print('^2[Phantom Gangs]^7 Server loaded. Gangs: ' .. TableLength(gangs))
    end
end)

-- Helper
function TableLength(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end
