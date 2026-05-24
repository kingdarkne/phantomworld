fx_version 'cerulean'
game 'gta5'

author 'Phantom World'
description 'Phantom Weapons - GTA Online Style Weapon Wheel & Ammu-Nation'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/weapon_wheel.lua',
    'client/ammu_nation.lua',
    'client/weapon_customization.lua',
    'client/weapon_locker.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/store.lua',
    'server/save_loadout.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}
