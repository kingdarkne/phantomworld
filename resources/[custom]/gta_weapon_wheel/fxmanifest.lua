fx_version 'cerulean'
game 'gta5'

description 'GTA-Online Style Weapon Wheel - Integrated with ox_inventory/qbx_core'
version '1.0.0'
author 'Cascade'
repository 'https://github.com/yourusername/gta_weapon_wheel'

lua54 'yes'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_inventory',
    'qbx_core',
    'ox_lib',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
