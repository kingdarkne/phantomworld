-- Helper client functions for checking rank on the client side.

local Rank = {}

--- Get current player level from XNLRankBar (native GTAO rank)
--- @return number level
function Rank.GetLevel()
    local ok, level = pcall(function()
        return exports.XNLRankBar:Exp_XNL_GetCurrentPlayerLevel()
    end)
    if not ok or not level then
        return 0
    end
    return tonumber(level) or 0
end

exports('GetLevel', Rank.GetLevel)

-- Simple grouped weapon rank requirements, loosely following GTA Online-style progression.
local WeaponRank = {
    melee = 1,
    pistol = 1,
    smg = 5,
    shotgun = 8,
    rifle = 10,
    lmg = 15,
    sniper = 20,
    heavy = 25,
    throwable = 5,
}

local function classifyWeapon(weaponName)
    weaponName = weaponName:lower()

    if weaponName:find('knife') or weaponName:find('bat') or weaponName:find('machete')
        or weaponName:find('poolcue') or weaponName:find('hatchet') or weaponName:find('crowbar')
        or weaponName:find('battleaxe') or weaponName:find('hammer') or weaponName:find('wrench') then
        return 'melee'
    end

    if weaponName:find('pistol') or weaponName:find('revolver') or weaponName:find('snspistol')
        or weaponName:find('vintagepistol') or weaponName:find('heavypistol') then
        return 'pistol'
    end

    if weaponName:find('smg') or weaponName:find('microsmg') or weaponName:find('minismg')
        or weaponName:find('machinepistol') or weaponName:find('combatpdw') then
        return 'smg'
    end

    if weaponName:find('shotgun') then
        return 'shotgun'
    end

    if weaponName:find('rifle') or weaponName:find('carbine') or weaponName:find('specialcarbine')
        or weaponName:find('bullpuprifle') or weaponName:find('compactrifle') then
        return 'rifle'
    end

    if weaponName:find('mg') or weaponName:find('gusenberg') then
        return 'lmg'
    end

    if weaponName:find('sniper') or weaponName:find('marksmanrifle') then
        return 'sniper'
    end

    if weaponName:find('rpg') or weaponName:find('launcher') or weaponName:find('minigun')
        or weaponName:find('railgun') then
        return 'heavy'
    end

    if weaponName:find('grenade') or weaponName:find('stickybomb') or weaponName:find('proxmine')
        or weaponName:find('molotov') or weaponName:find('pipebomb') or weaponName:find('snowball')
        or weaponName:find('flare') or weaponName:find('bzgas') or weaponName:find('ball') then
        return 'throwable'
    end

    return nil
end

--- Check if player can use a given weapon name.
--- Returns allowed:boolean, requiredRank:number, currentRank:number
function Rank.CanUseWeapon(weaponName)
    local class = classifyWeapon(weaponName)
    local level = Rank.GetLevel()
    if not class then
        return true, 0, level
    end
    local required = WeaponRank[class] or 1
    if level < required then
        return false, required, level
    end
    return true, required, level
end

exports('CanUseWeapon', Rank.CanUseWeapon)

-- Very simple vehicle rank gating by vehicle class (GTA classes 0–21).
-- This is NOT 1:1 with GTA Online's unlock table but gives similar progression.
local VehicleClassRank = {
    [0] = 1,   -- Compacts
    [1] = 1,   -- Sedans
    [2] = 1,   -- SUVs
    [3] = 3,   -- Coupes
    [4] = 3,   -- Muscle
    [5] = 5,   -- Sports Classics
    [6] = 10,  -- Sports
    [7] = 1,   -- Super
    [8] = 1,   -- Motorcycles
    [9] = 5,   -- Off-road
    [10] = 5,  -- Industrial
    [11] = 5,  -- Utility
    [12] = 1,   -- Vans
    [13] = 1,  -- Cycles
    [14] = 1,  -- Boats
    [15] = 1,  -- Helicopters
    [16] = 1,  -- Planes
    [17] = 5,  -- Service
    [18] = 5,  -- Emergency
    [19] = 10, -- Military
    [20] = 10, -- Commercial
    [21] = 1,  -- Trains
}

--- Check if player can drive a vehicle class.
--- Returns allowed:boolean, requiredRank:number, currentRank:number
function Rank.CanDriveClass(vehClass)
    local required = VehicleClassRank[vehClass]
    if not required then
        return true, 0, Rank.GetLevel()
    end
    local level = Rank.GetLevel()
    if level < required then
        return false, required, level
    end
    return true, required, level
end

exports('CanDriveClass', Rank.CanDriveClass)

-- Soft enforcement: if player enters a high-class vehicle below required rank, kick them out.
CreateThread(function()
    local lastVeh = 0
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and veh ~= lastVeh and GetPedInVehicleSeat(veh, -1) == ped then
                lastVeh = veh
                local class = GetVehicleClass(veh)
                local allowed, required, current = Rank.CanDriveClass(class)
                if not allowed then
                    TaskLeaveVehicle(ped, veh, 16)
                    SetVehicleEngineOn(veh, false, true, true)
                    local msg = ('You need rank %s to drive this type of vehicle. You are rank %s.'):format(required, current)
                    if GetResourceState('qbx_core') == 'started' then
                        exports.qbx_core:Notify(msg, 'error')
                    else
                        local core = DrGetQBCore()
                        if core and core.Functions then
                            core.Functions.Notify(msg, 'error')
                        else
                            lib.notify({ description = msg, type = 'error' })
                        end
                    end
                end
            end
        else
            lastVeh = 0
        end
    end
end)
