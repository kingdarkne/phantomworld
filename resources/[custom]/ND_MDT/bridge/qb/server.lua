local Bridge = {}

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getPlayerInfo(src)
    local player = getPlayer(src)
    if not player then
        return { job = "", jobLabel = "", firstName = "", lastName = "", callsign = "", img = "user.jpg", characterId = "" }
    end
    local pd       = player.PlayerData
    local charinfo = pd.charinfo  or {}
    local job      = pd.job       or {}
    local meta     = pd.metadata  or {}
    return {
        job         = job.name            or "",
        jobLabel    = job.label           or "",
        firstName   = charinfo.firstname  or "",
        lastName    = charinfo.lastname   or "",
        callsign    = meta.callsign       or "",
        img         = meta.img            or "user.jpg",
        characterId = pd.citizenid        or "",
        isBoss      = job.isboss          or false,
    }
end

Bridge.getPlayerInfo = getPlayerInfo

function Bridge.nameSearch(src, first, last)
    if not config.policeAccess[getPlayerInfo(src).job] then return false end
    local result = MySQL.query.await("SELECT citizenid, charinfo FROM players")
    if not result then return {} end
    local profiles = {}
    for i = 1, #result do
        local row = result[i]
        local ok, ci = pcall(json.decode, row.charinfo or "{}")
        if not ok then ci = {} end
        local fn = (ci.firstname or ""):lower()
        local ln = (ci.lastname  or ""):lower()
        if (first == "" or fn:find(first, 1, true)) and (last == "" or ln:find(last, 1, true)) then
            profiles[row.citizenid] = {
                firstName = ci.firstname,
                lastName  = ci.lastname,
                dob       = ci.birthdate,
                gender    = ci.gender,
                phone     = ci.phone,
                ethnicity = ci.nationality,
                img       = "user.jpg",
            }
        end
    end
    return profiles
end

function Bridge.characterSearch(source, characterId)
    local result = MySQL.query.await("SELECT citizenid, charinfo FROM players WHERE citizenid = ?", {tostring(characterId)})
    if not result then return {} end
    local profiles = {}
    for i = 1, #result do
        local row = result[i]
        local ok, ci = pcall(json.decode, row.charinfo or "{}")
        if not ok then ci = {} end
        profiles[row.citizenid] = {
            firstName = ci.firstname,
            lastName  = ci.lastname,
            dob       = ci.birthdate,
            gender    = ci.gender,
            phone     = ci.phone,
            ethnicity = ci.nationality,
            img       = "user.jpg",
        }
    end
    return profiles
end

function Bridge.viewVehicles(source, searchBy, data)
    if not config.policeAccess[getPlayerInfo(source).job] then return false end
    local result
    if searchBy == "plate" then
        result = MySQL.query.await("SELECT * FROM player_vehicles WHERE plate RLIKE ?", {data})
    elseif searchBy == "owner" then
        result = MySQL.query.await("SELECT * FROM player_vehicles WHERE citizenid = ?", {data})
    end
    if not result then return {} end
    local vehicles = {}
    for i = 1, #result do
        local item = result[i]
        local ownerRow = MySQL.query.await("SELECT charinfo FROM players WHERE citizenid = ?", {item.citizenid})
        local ownerInfo = {}
        if ownerRow and ownerRow[1] then
            local ok, ci = pcall(json.decode, ownerRow[1].charinfo or "{}")
            if ok then ownerInfo = ci end
        end
        vehicles[item.id] = {
            id        = item.id,
            plate     = item.plate,
            make      = item.vehicle,
            model     = item.vehicle,
            stolen    = false,
            character = {
                firstName   = ownerInfo.firstname or "",
                lastName    = ownerInfo.lastname  or "",
                characterId = item.citizenid,
            }
        }
    end
    return vehicles
end

function Bridge.getProperties(characterId)
    return {}
end

function Bridge.getRecords(characterId)
    local result = MySQL.query.await("SELECT records FROM nd_mdt_records WHERE `character` = ? LIMIT 1", {characterId})
    if not result or not result[1] then return {}, false end
    return json.decode(result[1].records), true
end

function Bridge.getLicenses(characterId)
    local result = MySQL.query.await("SELECT metadata FROM players WHERE citizenid = ?", {tostring(characterId)})
    if not result or not result[1] then return {} end
    local ok, meta = pcall(json.decode, result[1].metadata or "{}")
    if not ok or not meta.licenses then return {} end
    local out = {}
    for licType, status in pairs(meta.licenses) do
        out[#out + 1] = { type = licType, status = status }
    end
    return out
end

function Bridge.editPlayerLicense(characterId, identifier, newStatus)
    local result = MySQL.query.await("SELECT metadata FROM players WHERE citizenid = ?", {tostring(characterId)})
    if not result or not result[1] then return end
    local ok, meta = pcall(json.decode, result[1].metadata or "{}")
    if not ok then meta = {} end
    if not meta.licenses then meta.licenses = {} end
    meta.licenses[identifier] = newStatus
    MySQL.update("UPDATE players SET metadata = ? WHERE citizenid = ?", {json.encode(meta), tostring(characterId)})
end

function Bridge.createInvoice(characterId, fine)
    print(("[ND_MDT] Invoice queued — CitizenID: %s, Amount: $%s"):format(tostring(characterId), tostring(fine)))
end

function Bridge.getPlayerImage(characterId)
    local result = MySQL.query.await("SELECT metadata FROM players WHERE citizenid = ?", {tostring(characterId)})
    if not result or not result[1] then return "user.jpg" end
    local ok, meta = pcall(json.decode, result[1].metadata or "{}")
    return ok and meta.img or "user.jpg"
end

function Bridge.viewEmployees(src, search)
    if not config.policeAccess[getPlayerInfo(src).job] then return end
    local employees = {}
    local allPlayers = exports.qbx_core:GetPlayers()
    for _, player in pairs(allPlayers) do
        local pd      = player.PlayerData
        local job     = pd.job      or {}
        local ci      = pd.charinfo or {}
        local meta    = pd.metadata or {}
        if config.policeAccess[job.name] then
            local fullName = ("%s %s %s"):format(ci.firstname or "", ci.lastname or "", tostring(meta.callsign or ""))
            if not search or search == "" or fullName:lower():find(search:lower(), 1, true) then
                employees[#employees + 1] = {
                    source   = pd.source,
                    charId   = pd.citizenid,
                    first    = ci.firstname,
                    last     = ci.lastname,
                    callsign = meta.callsign,
                    job      = job.name,
                    jobInfo  = { rank = job.grade and job.grade.level or 0, isBoss = job.isboss },
                    dob      = ci.birthdate,
                    gender   = ci.gender,
                    phone    = ci.phone,
                    img      = meta.img,
                }
            end
        end
    end
    return employees
end

function Bridge.updateEmployeeRank(src, update)
    return false, "Rank management requires ND_Core"
end

function Bridge.employeeUpdateCallsign(src, charid, callsign)
    local result = MySQL.query.await("SELECT metadata FROM players WHERE citizenid = ?", {tostring(charid)})
    if not result or not result[1] then return false, "Player not found" end
    local ok, meta = pcall(json.decode, result[1].metadata or "{}")
    if not ok then meta = {} end
    meta.callsign = callsign
    MySQL.update("UPDATE players SET metadata = ? WHERE citizenid = ?", {json.encode(meta), tostring(charid)})
    local onlinePlayer = exports.qbx_core:GetPlayerByCitizenId(tostring(charid))
    if onlinePlayer then onlinePlayer.Functions.SetMetaData("callsign", callsign) end
    return callsign
end

function Bridge.removeEmployeeJob(src, charid)
    local player = exports.qbx_core:GetPlayerByCitizenId(tostring(charid))
    if player then
        player.Functions.SetJob("unemployed", 0)
        return true
    end
    return false, "Player must be online to be fired"
end

function Bridge.invitePlayerToJob(src, target)
    local srcPlayer = getPlayer(src)
    local tgtPlayer = getPlayer(target)
    if not srcPlayer or not tgtPlayer then return false end
    tgtPlayer.Functions.SetJob(srcPlayer.PlayerData.job.name, 0)
    return true
end

function Bridge.getStolenVehicles()
    local plates = {}
    local bolos = MySQL.query.await("SELECT `data` FROM `nd_mdt_bolos` WHERE `type` = 'vehicle'")
    if not bolos then return plates end
    for i = 1, #bolos do
        local info = json.decode(bolos[i].data) or {}
        if info.plate then plates[#plates + 1] = info.plate end
    end
    return plates
end

function Bridge.vehicleStolen(id, stolen, plate)
    print(("[ND_MDT] Vehicle stolen status — plate: %s stolen: %s"):format(tostring(plate), tostring(stolen)))
end

function Bridge.updatePlayerMetadata(source, characterId, key, value)
    local player = getPlayer(source)
    if player then player.Functions.SetMetaData(key, value) end
end

return Bridge
