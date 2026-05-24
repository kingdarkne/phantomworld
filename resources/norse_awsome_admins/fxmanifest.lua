fx_version 'cerulean'
game 'gta5'

author 'Norse Development | Sir Kurz'
description 'Advanced ESX/QBCore/Qbox Admin Menu'
version '1.0.0'
lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/**/*',
    'images_cars/*',
    'images_cars/**/*'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/config_exploit.lua',
    'config/config_anticheat.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/stress-relief.lua',
    'server/troll.lua',
    'server/anticheat.lua',
    'server/exploit_monitor.lua',
    'server/healing_items.lua',
    'server/main.lua',
    'server/economy_stats.lua',
    'server/stats_player.lua',
    'server/live_map.lua'
}

client_scripts {
    'client/troll.lua',
    'client/mobhit.lua',
    'client/live_map.lua',
    'client/healing_items.lua',
    'client/keybind.lua',
    'client/main.lua'
}

dependencies {
    'ox_target',
    -- 'es_extended',
    -- 'qb-core',
    'qbx_core',
    -- 'ox_inventory',
    -- 'qb-inventory',
    -- 'qs-inventory',
    -- 'mf-inventory',
    -- 'esx_skin',
    -- 'qb-clothing',
    -- 'fivem-appearance',
    -- 'legacyfuel',
    -- 'ox_fuel'
}

escrow_ignore { 
'config/config.lua', 
'config/config_exploit.lua',
'config/config_anticheat.lua',
'config/config-stress-items.lua', 
'sql/oxoadmin_bans.sql', 
'sql/oxoadmin_names.sql',
'README.md',
'config/illegal_items.lua',
}
dependency '/assetpacks'