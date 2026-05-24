local Bridge = {}

function Bridge.getPlayerInfo()
    local QBCore = exports['qbx_core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayerData()
    if not player then
        return { job = "", jobLabel = "", firstName = "", lastName = "", callsign = "", img = "user.jpg", isBoss = false }
    end
    return {
        job       = player.job and player.job.name or "",
        jobLabel  = player.job and player.job.label or "",
        firstName = player.charinfo and player.charinfo.firstname or "",
        lastName  = player.charinfo and player.charinfo.lastname or "",
        callsign  = player.metadata and player.metadata.callsign or "",
        img       = player.metadata and player.metadata.img or "user.jpg",
        isBoss    = player.job and player.job.isboss or false,
    }
end

function Bridge.hasAccess(job)
    return config.policeAccess[job] or config.fireAccess[job]
end

function Bridge.rankName()
    local QBCore = exports['qbx_core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayerData()
    return player and player.job and player.job.grade and player.job.grade.name or ""
end

function Bridge.getCitizenInfo(character, info)
    return {
        img         = info.img or "user.jpg",
        characterId = character,
        firstName   = info.firstName,
        lastName    = info.lastName,
        dob         = info.dob,
        gender      = info.gender,
        phone       = info.phone,
        ethnicity   = info.ethnicity,
    }
end

function Bridge.getRanks(job)
    return nil
end

return Bridge
