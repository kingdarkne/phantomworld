Config = {}
--[[    
      ╔══════════════════════════════════════════════════════════════╗
      ║           ADMIN SYSTEM — CONFIGURATION                       ║
      ║           Norse Development | by Sir Kurz                    ║
      ╚══════════════════════════════════════════════════════════════╝
]]

Config.ResourceName = GetCurrentResourceName()
Config.Debug = false

-- 'auto','esx','qbcore','qbox','standalone'
Config.Framework = 'qbox'

-- Stress backend for the Self "Stress" action
-- 'auto'  = try ESX (esx_status), then QB (qb-hud), then jg-stress-addon
-- 'esx'   = force ESX esx_status backend
-- 'qb'    = force qb-hud backend
-- 'jg'    = force jg-stress-addon (hud:server:RelieveStress)
-- 'none'  = disable automatic stress clearing (button will just warn)
Config.StressBackend = 'jg'

-- Default world density percentages for Server tab controls
Config.WorldDensity = {
    Vehicles = 100,  -- 100% vehicle traffic by default
    Peds     = 100   -- 100% pedestrian density by default
}

Config.WorldDensityAutoApply = {
    Enabled = true,
    UseSaved = true
}

Config.CleanupSchedule = {
    Enabled = false,
    RunAllOnStart = false,
    RunAllOnFirstJoin = false,
    VehiclesMinutes = 0,
    ObjectsMinutes = 0,
    PedsMinutes = 0,
    AllMinutes = 0
}

Config.ScreenFilters = {
    { key='none', label='No Filters (Default)', clear=true },
    { key='drug', label='Drug Trip', timecycle='drug_flying_01', strength=1.0, screenEffect='DrugsMichaelAliensFight', shake='SMALL_EXPLOSION_SHAKE', shakeAmp=0.35 },
    { key='cinema', label='Cinema', timecycle='cinema', strength=1.0 },
    { key='noir', label='Noir', timecycle='NG_filmnoir_BW01', strength=1.0 },
    { key='vibrant', label='Vibrant', timecycle='rply_saturation', strength=1.0 },
    { key='bright', label='Bright + Color Boost', timecycle='MP_Powerplay', strength=0.85 },
    { key='crystal', label='Crystal Clear (Super Bright)', timecycle='MP_Powerplay', strength=1.0 },
    { key='foggy', label='Foggy', timecycle='foggy', strength=1.0 },
    { key='heat', label='Heat', timecycle='heat', strength=1.0 },
    { key='underwater', label='Underwater', timecycle='underwater', strength=1.0 }
}

Config.LiveMap = {
    ClientReportIntervalMs = 1000,
    ClientIdleIntervalMs = 2000,
    ServerTickMs = 500,
    ServerUpdateIntervalNearMs = 1000,
    ServerUpdateIntervalFarMs = 3000,
    DistanceBasedIntervals = true,
    DistanceThreshold = 200.0
}

Config.StaffTags = {
    MaxDistance = 40.0,
    HeadOffsetZ = 1.05,
    RequireLineOfSight = true,
    RaycastIntervalMs = 150
}

Config.Commands = {
    admin   = 'admin',
    ban     = 'ban',
    kick    = 'kick',
    noclip  = 'noclip',
    clearinv= 'clearinv',
    skin    = 'skin',
    mobhit  = 'mobhit'
}

Config.OpenKey = 'HOME'

Config.ESXGroups = { admin = { 'admin','mod','superadmin' }, super = { 'superadmin' } }
Config.QBGroups  = { admin = { 'admin','god' }, super = { 'god' } }
Config.QBOXGroups= { admin = { 'god', 'admin' }, super = { 'god' } }

-- Admin duty job integration
-- When Enabled=true:
--  - Toggling duty ON switches admin job to Config.DutyJob.Job with mapped grade by admin role.
--  - Toggling duty OFF restores the previous job/grade from before duty started.
--  - If admin changes their own job from panel while on duty, they are forced OFF duty and keep the selected job.
Config.DutyJob = {
    Enabled = true,
    Job = 'duty',
    DefaultGrade = 0,

    -- Map your OxoAdmin role names to duty job grades.
    -- Role names come from roles.json staff role labels (or framework group fallback when no role assigned).
    RoleGrades = {
        ['Mastermind'] = 10,
        ['iFlow Manager'] = 7,
		['Head Admin'] = 6,
        ['Admin'] = 5,
        ['Lead Moderator'] = 4,
        ['Moderator'] = 3,
        ['Trainee Moderator'] = 2,
		['Vehicle Manager'] = 1,
		['Tester'] = 0,
    }
}
	
Config.Perms = {
    MenuOpen       = { ace='oxoadmin.menu',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Self           = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Player         = { ace='oxoadmin.player',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Server         = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Vehicle        = { ace='oxoadmin.vehicle',    esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Dev            = { ace='oxoadmin.dev',        esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Zones          = { ace='oxoadmin.zones',      esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Bans           = { ace='oxoadmin.bans',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    Console        = { ace='oxoadmin.console',    esx=Config.ESXGroups.super, qb=Config.QBGroups.super, qbox=Config.QBOXGroups.super },
    Code           = { ace='oxoadmin.code',       esx=Config.ESXGroups.super, qb=Config.QBGroups.super, qbox=Config.QBOXGroups.super },
    Roles          = { ace='oxoadmin.roles',      esx=Config.ESXGroups.super, qb=Config.QBGroups.super, qbox=Config.QBOXGroups.super },
    Statistics     = { ace='oxoadmin.statistics', esx=Config.ESXGroups.super, qb=Config.QBGroups.super, qbox=Config.QBOXGroups.super },
    StatisticsView = { ace='oxoadmin.statistics', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    StaffNotesView  = { ace='oxoadmin.staffnotes', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    StaffNotesAdd   = { ace='oxoadmin.staffnotes', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    LiveMap        = { ace='oxoadmin.livemap',    esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    -- Fine-grained Self permissions
    SelfHeal       = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfRevive     = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfNoclip     = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfInvincible = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfInvisible  = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfAmmo       = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfArmor      = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfStress     = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfWanted     = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSuperjump  = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfRunFast2x  = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfTeleportMarked = { ace='oxoadmin.self',   esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfTeleportMarkedNoVehicle = { ace='oxoadmin.self',   esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSkin       = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }, -- legacy: all skin actions
    SelfSkinMenu   = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }, -- open skin menu only
    SelfPed        = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }, -- legacy: all ped actions
    SelfPedSet     = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }, -- set ped
    SelfPedClear   = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }, -- clear ped
    SelfPedMenu    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }, -- open ped shop menu
    SelfDuty       = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfStaffName  = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfRpName     = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob0    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob1    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob2    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob3    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob4    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob5    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfSetJob6    = { ace='oxoadmin.self',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    SelfGiveMoney  = { ace='oxoadmin.self',       esx=Config.ESXGroups.super, qb=Config.QBGroups.super, qbox=Config.QBOXGroups.super },

    -- Fine-grained Dev permissions
    DevLightning   = { ace='oxoadmin.dev',        esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    DevGodshand    = { ace='oxoadmin.dev',        esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },

    -- Fine-grained Bans permissions
    BansPardon     = { ace='oxoadmin.bans',       esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },

    -- Command permissions
    CmdMobhit      = { ace='oxoadmin.mobhit',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },

    -- Fine-grained Player permissions
    PlayerList        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerKick        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerBan         = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerPrisonBan   = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerIsolation   = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerIsolationPardon = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerHeal        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerRevive      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerStress      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerWanted      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerKill        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerWarn        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerMessage     = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerSetJob      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerBring       = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerGoto        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerSpectate    = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerFreeze      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerUnfreeze    = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerNoclip      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerInvincible  = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerInvisible   = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerClearInv    = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerMoney       = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerMoneyView   = { ace='oxoadmin.player',  esx=Config.ESXGroups.mod,   qb=Config.QBGroups.mod,   qbox=Config.QBOXGroups.mod   },
    PlayerGiveItem        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerSkin            = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerCheckInv        = { ace='oxoadmin.player',  esx=Config.ESXGroups.mod,   qb=Config.QBGroups.mod,   qbox=Config.QBOXGroups.mod   },
    PlayerOpenInvEdit     = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerConfiscateIllegal = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerOpenInv         = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerOpenInvView     = { ace='oxoadmin.player',  esx=Config.ESXGroups.mod,   qb=Config.QBGroups.mod,   qbox=Config.QBOXGroups.mod   },
    PlayerTroll       = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollSlap       = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollLaunch     = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollScreen     = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollFire       = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollUfo        = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollNpcKidnap  = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollAnimal     = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollNpcs       = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollClone      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollFlipveh    = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollSlowwalk   = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollCam2d      = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollCamflip    = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    PlayerTrollMobhit     = { ace='oxoadmin.player',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },

    -- Fine-grained Server permissions
    ServerCleanup  = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    ServerWeather  = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    ServerAnnounce = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    ServerChaos    = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    ServerFilters  = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    ServerDensity  = { ace='oxoadmin.server',     esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },

    -- Fine-grained Vehicle permissions
    VehicleSpawn        = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleRepair       = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleDeleteClosest= { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleMaxMods      = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleMaxFuel      = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehiclePlate        = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleColor        = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleLock         = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleUnlock       = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    VehicleTorque       = { ace='oxoadmin.vehicle', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    CmdBan         = { ace='oxoadmin.cmd.ban',    esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    CmdKick        = { ace='oxoadmin.cmd.kick',   esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    CmdNoclip      = { ace='oxoadmin.cmd.noclip', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    CmdClearInv    = { ace='oxoadmin.cmd.clear',  esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    CmdSkin        = { ace='oxoadmin.cmd.skin',   esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin },
    CmdMobhit      = { ace='oxoadmin.cmd.mobhit', esx=Config.ESXGroups.admin, qb=Config.QBGroups.admin, qbox=Config.QBOXGroups.admin }
}

Config.Inventory = 'ox_inventory'

-- Vehicle ownership database config (for Vehicle tab compatibility)
-- ESX uses 'owned_vehicles' with columns: owner, plate, vehicle, stored, garage, fuel, etc.
-- QB uses 'player_vehicles' with columns: citizenid, vehicle, plate, garage, state, etc.
Config.Vehicles = {
    Table       = 'player_vehicles',
    OwnerColumn = 'citizenid',
    PlateColumn = 'plate',
    VehicleColumn = 'vehicle',
    StoredColumn  = 'state',
    GarageColumn  = 'garage',
}
Config.IllegalItems = {}

-- Skin/Clothing menu backend used by /skin and the UI Skin button
-- Supported: 'rcore_clothing', 'esx_skin', 'qb-clothing', 'fivem-appearance'
Config.Skin = 'rcore_clothing'

-- Vehicle keys backend (lock/unlock integration)
-- Currently only 'none' is supported (no external keys resources are called yet)
Config.VehicleKeys = 'none'

-- Supported: 'lyre_fuel' (Lyre Scripts Fuel), 'lc_fuel' (legacy), or anything else for native fallback
Config.Fuel = 'lyre_fuel'
Config.ArmorBackend = 'native'

-- Notification backend: 'lation', 'ox', 'esx', or 'auto'
Config.Notify = 'lation'

Config.SelfDefaultPed = `mp_m_freemode_01`

Config.Themes = {
    dark = {
        label = 'Dark (Blue/Green)',
        colors = {
            primary      = '#22c55e',   -- main green accent
            primaryAlt   = '#06b6d4',   -- secondary teal/blue accent
            bg           = 'rgba(2,6,23,0.28)',
            surface      = 'rgba(15,23,42,0.70)',
            panel        = 'rgba(15,23,42,0.45)',
            borderSoft   = '#374151',
            text         = '#e5e7eb',
            muted        = '#9ca3af',
            dark         = '#020617',
            danger       = '#ef4444',   -- generic danger/red
            offline      = '#990000',   -- offline / off-duty red
            offlineText  = '#fef2f2'
        }
    },
    light = {
        label = 'Light (Blue)',
        colors = {
            primary      = '#0ea5e9',   -- sky blue
            primaryAlt   = '#6366f1',   -- indigo
            -- Match the dark theme's see-through feeling but with light tones
            bg           = 'rgba(249,250,251,0.28)',
            surface      = 'rgba(255,255,255,0.70)',
            panel        = 'rgba(255,255,255,0.45)',
            borderSoft   = '#d1d5db',
            text         = '#111827',
            muted        = '#6b7280',
            dark         = '#020617',
            danger       = '#ef4444',
            offline      = '#990000',
            offlineText  = '#fee2e2'
        }
    }
}

Config.DefaultTheme = 'dark'

Config.BansFile = 'bans.json'
Config.PrisonBansFile = 'prison_bans.json'
Config.ZonesFile = 'zones.json'
Config.RolesFile = 'roles.json'
Config.ActionsFile = 'actions.json'

-- Prison backend used for Prison Bans
-- 'tk_jail' (default) or 'rcore_prison'
Config.PrisonBackend = 'tk_jail'

Config.EconomyStats = {
    Enabled = true,
    RefreshSeconds = 60,
    TransactionsTable = 'economy_transactions',
    PlayersTable = 'users',
    IdentifierColumn = 'identifier',
    NameColumn = 'firstname',
    LastNameColumn = 'lastname',
    JobColumn = 'job',
    PlaytimeColumn = 'playtime',
    AccountsColumn = 'accounts',
    WalletKey = 'money',
    BankKey = 'bank',
    BlackKey = 'black_money',
    IllegalJobs = { 'cartel', 'mafia', 'gang', 'drugdealer' },
    GrayJobs = { 'mechanic', 'taxi' },
    AccountCategories = {
        money = 'wallet',
        bank = 'banking',
        black_money = 'black_market'
    },
    Shops = {
        TransactionsTable = 'lation_shops_transactions',
        ShopsTable = 'lation_shops'
    },
    Drugs = {
        StatsTable = 'lunar_drugscreator_stats'
    },
    Crypto = {
        StatsTable = 'ono_laptop_crypto_stats',
        TransactionsTable = 'crypto_transactions'
    },
    Gangs = {
        Table = 'electus_gangs'
    }
}

-- Isolation system configuration
Config.Isolation = {
    Enabled = true,
    Cells = {
        vec4(1691.90, 2542.43, 45.63, 0.0),
        vec4(1691.45, 2545.59, 45.63, 0.0),
        vec4(1691.35, 2549.03, 45.63, 0.0),
        vec4(1692.18, 2552.40, 45.63, 0.0),
        vec4(1691.82, 2555.96, 45.63, 0.0),
        vec4(1651.22, 2571.32, 45.56, 0.0),
        vec4(1641.88, 2569.88, 45.56, 0.0),
        vec4(1629.34, 2570.39, 45.56, 0.0)
    },
    -- Base time in minutes for each offense count
    BaseMinutes = {
        [1] = 60,  -- 1st offense: 1 hour
        [2] = 120, -- 2nd offense: 2 hours
        [3] = 180  -- 3rd offense: 3 hours
    },
    -- For 4th+ offenses: 3 hours + (offenseCount - 3) * 60
    IncrementMinutes = 60,
    -- Maximum distance allowed before a player is forced back to isolation
    ReturnRadius = 15.0,
    -- Interval in minutes for isolation countdown notifications sent to the player
    CountdownNotifyInterval = 5
}

Config.Log = true

Config.Duty = {}
Config.Duty.PayEnabled = true
Config.Duty.PayInterval = 600
Config.Duty.PayAmount = 500
Config.Duty.PayAccount = 'money'
-- Config.Duty.RolePay = { ... } -- Duty Pay is now configured directly in the Roles tab in the admin menu UI

Config.Duty.RequirementEnabled = true
Config.Duty.RequirementSecondsLast30 = 12*3600
Config.Duty.RequirementCheckInterval = 6*3600
Config.Duty.InactivityEnabled = true
Config.Duty.InactivitySeconds = 15*60

Config.AdminVehicles = {
    { label = 'Admin Car', model = 'adder', plate = 'ADMIN' }
}

Config.MobHit = {
    Command = 'mobhit',
    AllowedJob = 'police',
    RewardAmount = 250000, -- amount to pay when target survives
    RewardAccount = 'black_money', -- ESX: 'black_money'; QB/QBOX: custom handling inside giveMoney

    MobPeds = {
        'g_m_m_armboss_01',
        'g_m_m_armgoon_01',
        'g_m_m_armlieut_01',
        'g_m_y_ballaeast_01',
        'g_m_y_ballaorig_01',
        'g_m_y_ballasout_01',
        'g_m_y_famca_01',
        'g_m_y_famdnf_01',
        'g_m_y_famfor_01'
    },

    MobVehicles = {
        'schafter3',
        'cognoscenti',
        'sultan',
        'kuruma',
        'baller4'
    },

    MobSettings = {
        SpawnCount = 10,
        SpawnDistance = 150.0,
        AttackDistance = 15.0,
        DespawnDistance = 300.0,
        VehicleChance = 0.8,
        WeaponAccuracy = 100,
        Weapons = {
            'weapon_pumpshotgun',
            'weapon_heavyrifle',
            'weapon_carbinerifle_mk2',
            'weapon_revolver',
            'WEAPON_PISTOL',
            'WEAPON_MICROSMG',
            'weapon_precisionrifle',
            'weapon_rayminigun'
        }
    }
}
