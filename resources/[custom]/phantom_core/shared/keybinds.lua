-- Phantom World Unified Keybind Configuration
-- All keybinds are centralized here to avoid conflicts across the entire server

Config = Config or {}

Config.Keybinds = {
    -- F1-F10: Main Menus & Admin
    AdminMenu = {
        key = 'F1',
        description = 'Open Admin Menu',
        scripts = {'norse_awsome_admins', 'dr-admin'}
    },
    
    Noclip = {
        key = 'F2',
        description = 'Toggle Noclip (Admin)',
        scripts = {'vMenu'}
    },
    
    VehicleMenu = {
        key = 'F3',
        description = 'Open Vehicle Calling Menu',
        scripts = {'vehicle_caller'}
    },
    
    Phone = {
        key = 'F4',
        description = 'Open Phone',
        scripts = {'qbx_phone', 'npwd'}
    },
    
    vMenu = {
        key = 'F5',
        description = 'Open vMenu',
        scripts = {'vMenu'}
    },
    
    MechanicTablet = {
        key = 'F6',
        description = 'Open Mechanic Tablet',
        scripts = {'phantom_mechanic'}
    },
    
    GangMenu = {
        key = 'F7',
        description = 'Open Gang Menu',
        scripts = {'phantom_gangs'}
    },
    
    CopsVsRobbers = {
        key = 'F8',
        description = 'Open Cops vs Robbers',
        scripts = {'phantom_copsvrobbers'}
    },
    
    ToggleHUD = {
        key = 'F9',
        description = 'Toggle HUD',
        scripts = {'tuff-hud'}
    },
    
    PhantomMenu = {
        key = 'F10',
        description = 'Open Phantom Main Menu',
        scripts = {'dr-mainmenu'}
    },
    
    -- F11-F12: Voice & Misc
    VoiceCycle = {
        key = 'F11',
        description = 'Cycle Voice Proximity',
        scripts = {'pma-voice'}
    },
    
    PlayerList = {
        key = 'F12',
        description = 'Open Player List',
        scripts = {'dr-playerlist'}
    },
    
    -- Core Interactions
    Interact = {
        key = 'E',
        description = 'Interact with objects/doors/vehicles',
        scripts = {'phantom_core', 'phantom_heists', 'phantom_garage', 'phantom_gangs', 'qb-doorlock'}
    },
    
    -- Combat & Weapons
    WeaponWheel = {
        key = 'TAB',
        description = 'Hold TAB — native GTA weapon wheel',
        scripts = {'gta_weapon_wheel', 'ox_inventory', '3dweaponwheel'}
    },
    
    HandsUp = {
        key = 'X',
        description = 'Hands Up',
        scripts = {'phantom_core', 'qb-smallresources'}
    },
    
    CancelEmote = {
        key = 'X',
        description = 'Cancel Emote',
        scripts = {'scully_emotemenu', 'dr-animationmenu'}
    },
    
    -- Vehicle Controls
    Seatbelt = {
        key = 'B',
        description = 'Toggle Seatbelt',
        scripts = {'tuff-hud', 'qb-smallresources'}
    },
    
    Engine = {
        key = 'G',
        description = 'Toggle Engine',
        scripts = {'qb-vehiclekeys', 'ps-hud'}
    },
    
    VehicleLock = {
        key = 'L',
        description = 'Toggle Vehicle Lock',
        scripts = {'qb-vehiclekeys'}
    },
    
    CruiseControl = {
        key = 'C',
        description = 'Toggle Cruise Control',
        scripts = {'qb-smallresources'}
    },
    
    -- Voice & Radio
    RadioTalk = {
        key = 'LMENU',
        description = 'Talk over Radio',
        scripts = {'pma-voice'}
    },
    
    Tackle = {
        key = 'SHIFT',
        description = 'Tackle Someone',
        scripts = {'qb-smallresources'}
    },
    
    -- Special Actions
    Scoreboard = {
        key = 'P',
        description = 'Open Scoreboard',
        scripts = {'phantom_copsvrobbers', 'tuff-scoreboard'}
    },
    
    Point = {
        key = 'Z',
        description = 'Toggle Pointing',
        scripts = {'qb-smallresources', 'dr-animationmenu'}
    },
    
    -- Police Specific
    PoliceMDT = {
        key = 'K',
        description = 'Open Police MDT',
        scripts = {'ps-mdt'}
    },
    
    Bodycam = {
        key = 'O',
        description = 'Exit Bodycam',
        scripts = {'dr-bodycam'}
    },
    
    -- Phone Actions
    AnswerPhone = {
        key = 'Y',
        description = 'Answer Phone Call',
        scripts = {'qbx_phone'}
    },
    
    DeclinePhone = {
        key = 'J',
        description = 'Decline Phone Call',
        scripts = {'qbx_phone'}
    },
    
    -- Inventory
    Inventory = {
        key = 'I',
        description = 'Open Inventory',
        scripts = {'ox_inventory', 'qb-inventory'}
    },
    
    Hotbar = {
        key = '1',
        description = 'Toggle Hotbar',
        scripts = {'ox_inventory', 'qb-inventory'}
    },
    
    -- Targeting
    EnableTargeting = {
        key = 'T',
        description = 'Enable Targeting',
        scripts = {'qb-target'}
    },
    
    -- Chat
    ToggleChat = {
        key = 'T',
        description = 'Toggle Chat',
        scripts = {'chat'}
    },
    
    -- Map
    Map = {
        key = 'M',
        description = 'Open Map',
        scripts = {'default', 'qbx_phone'}
    },
    
    -- Radar Gun
    RadarAim = {
        key = 'Q',
        description = 'Aim Radar Gun',
        scripts = {'qb-radargun'}
    },
    
    RadarIncrease = {
        key = 'UP',
        description = 'Increase Radar Range',
        scripts = {'qb-radargun'}
    },
    
    RadarDecrease = {
        key = 'DOWN',
        description = 'Decrease Radar Range',
        scripts = {'qb-radargun'}
    },
    
    -- Emote Menu
    EmoteMenu = {
        key = 'NUMPAD5',
        description = 'Open Emote Menu',
        scripts = {'scully_emotemenu', 'dr-animationmenu'}
    },
    
    -- Menu Focus
    MenuFocus = {
        key = 'RCTRL',
        description = 'Give Menu Focus',
        scripts = {'qb-menu'}
    },
    
    -- Door Remote
    DoorRemote = {
        key = 'H',
        description = 'Remote Door Trigger',
        scripts = {'qb-doorlock'}
    }
}

-- Export for other scripts to access
function GetKeybind(keybindName)
    local keybind = Config.Keybinds[keybindName]
    if keybind then
        return keybind.key
    end
    return nil
end

-- Export for use in other resources
exports('GetKeybind', GetKeybind)
