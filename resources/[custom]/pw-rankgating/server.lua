-- pw-rankgating — Phantom World weapon rank requirements
-- Uses ox_inventory RegisterHook to block weapon items below required rank

-- ============================================================
-- XNL rank formula (mirrors XNLRankBar client)
-- ============================================================
local RockstarRanks = {
    400,1050,1900,3050,4750,6250,8000,9900,12000,14250,16700,19350,22100,25100,28200,
    31500,34950,38550,42350,46250,50350,54600,59000,63550,68250,73100,78100,83250,88550,
    94000,99600,105350,111200,117250,123400,129700,136150,142750,149500,156350,163400,
    170500,177800,185250,192800,200500,208300,216300,224400,232600,241000,249500,258150,
    266900,275800,284800,294000,303250,312700,322250,331900,341700,351650,361700,371900,
    382250,392700,403250,413950,424800,435750,446800,458000,469350,480800,492350,504050,
    515900,527850,539900,552100,564400,576850,589400,602100,614900,627800,640850,654050,
    667300,680700,694250,707900,721650,735550,749550,763650,777900,792175
}

local function getLevelFromXP(xp)
    xp = tonumber(xp) or 0
    for i = 1, #RockstarRanks do
        if xp < RockstarRanks[i] then return i end
    end
    local base = RockstarRanks[#RockstarRanks]
    local lvl  = #RockstarRanks
    local step = 14325
    while xp >= base + step do
        base = base + step
        step = step + 25
        lvl  = lvl + 1
    end
    return lvl + 1
end

local function getPlayerLevel(source)
    local player = GetResourceState('qbx_core') == 'started' and exports.qbx_core:GetPlayer(source) or nil
    local cid    = player and player.PlayerData and player.PlayerData.citizenid
    if not cid then return 1 end
    local result = exports.oxmysql:executeSync('SELECT driving FROM experience WHERE cid = ?', { cid })
    local xp     = (result and result[1] and tonumber(result[1].driving)) or 0
    return getLevelFromXP(xp)
end

-- ============================================================
-- Weapon rank table  (fair GTA:O-style progression)
-- ============================================================
-- Add your custom weapons here using their ox_inventory item name
local WEAPON_RANKS = {
    -- Pistols
    weapon_pistol            = 1,
    weapon_pistol_mk2        = 10,
    weapon_combatpistol      = 5,
    weapon_appistol          = 5,
    weapon_snspistol         = 5,
    weapon_snspistol_mk2     = 15,
    weapon_heavypistol       = 20,
    weapon_vintagepistol     = 15,
    weapon_marksmanpistol    = 25,
    weapon_revolver          = 20,
    weapon_revolver_mk2      = 30,
    weapon_doubleaction      = 20,
    weapon_ceramicpistol     = 15,
    weapon_stungun           = 10,
    weapon_flaregun          = 5,

    -- SMGs / Machine Pistols
    weapon_microsmg          = 10,
    weapon_minismg           = 10,
    weapon_smg               = 15,
    weapon_smg_mk2           = 25,
    weapon_assaultsmg        = 20,
    weapon_machinepistol     = 15,
    weapon_combatpdw         = 20,
    weapon_gusenberg         = 30,

    -- Shotguns
    weapon_pumpshotgun       = 15,
    weapon_pumpshotgun_mk2   = 25,
    weapon_sawnoffshotgun    = 10,
    weapon_assaultshotgun    = 25,
    weapon_bullpupshotgun    = 30,
    weapon_musket            = 15,
    weapon_heavyshotgun      = 35,
    weapon_dbshotgun         = 20,
    weapon_autoshotgun       = 40,
    weapon_combatshotgun     = 40,

    -- Rifles
    weapon_assaultrifle      = 20,
    weapon_assaultrifle_mk2  = 35,
    weapon_carbinerifle      = 25,
    weapon_carbinerifle_mk2  = 40,
    weapon_advancedrifle     = 30,
    weapon_specialcarbine    = 35,
    weapon_specialcarbine_mk2= 50,
    weapon_bullpuprifle      = 30,
    weapon_bullpuprifle_mk2  = 45,
    weapon_compactrifle      = 25,
    weapon_militaryrifle     = 50,
    weapon_heavyrifle        = 55,

    -- MGs
    weapon_mg                = 35,
    weapon_combatmg          = 45,
    weapon_combatmg_mk2      = 60,

    -- Sniper Rifles
    weapon_sniperrifle       = 50,
    weapon_heavysniper       = 60,
    weapon_heavysniper_mk2   = 75,
    weapon_marksmanrifle     = 50,
    weapon_marksmanrifle_mk2 = 65,

    -- Heavy / Launchers (high rank)
    weapon_rpg               = 75,
    weapon_grenadelauncher   = 65,
    weapon_hominglauncher    = 80,
    weapon_minigun           = 100,
    weapon_firework          = 50,
    weapon_railgun           = 100,

    -- Thrown (light restrictions)
    weapon_grenade           = 15,
    weapon_stickybomb        = 25,
    weapon_proximitamine     = 35,
    weapon_pipebomb          = 20,
    weapon_molotov           = 10,
    weapon_bzgas             = 20,
    weapon_smokegrenade      = 5,

    -- Melee (no restriction — rank 1)
    weapon_knife             = 1,
    weapon_bat               = 1,
    weapon_bottle            = 1,
    weapon_crowbar           = 1,
    weapon_unarmed           = 1,
    weapon_flashlight        = 1,
    weapon_nightstick        = 1,
    weapon_hammer            = 1,
    weapon_hatchet           = 1,
    weapon_machete           = 1,
    weapon_dagger            = 1,
}

-- ============================================================
-- ox_inventory hook — block weapon item if rank too low
-- ============================================================
-- Freeroam default: disabled (setr pw_rankgating:enabled 1 to restore)
if GetConvarInt('pw_rankgating:enabled', 0) ~= 1 then
    print('^3[pw-rankgating]^7 Disabled (freeroam). setr pw_rankgating:enabled 1 to restore.')
    return
end

if GetResourceState('ox_inventory') == 'started' then
    exports.ox_inventory:registerHook('swapItems', function(payload)
        -- Only care about items being added to a player inventory (not dropped/container)
        if type(payload.toInventory) ~= 'number' then return end

        local item     = payload.item
        local itemName = item and item.name and item.name:lower()
        if not itemName then return end

        local required = WEAPON_RANKS[itemName]
        if not required or required <= 1 then return end

        local source = payload.toInventory
        local level  = getPlayerLevel(source)

        if level < required then
            TriggerClientEvent('ox_lib:notify', source, {
                type        = 'error',
                title       = 'Rank Required',
                description = ('Rank %d required for this weapon. Your rank: %d'):format(required, level),
                duration    = 6000,
            })
            return false -- cancel the item transfer
        end
    end)

    print('^2[pw-rankgating]^7 Weapon rank hook registered via ox_inventory')
else
    print('^1[pw-rankgating]^7 ox_inventory not started — weapon rank hook skipped')
end
