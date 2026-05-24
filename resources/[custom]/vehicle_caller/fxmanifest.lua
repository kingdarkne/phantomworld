fx_version 'cerulean'
game 'gta5'

description 'Vehicle Calling Menu - Easy vehicle spawning for owned/rented cars'
version '1.0.0'
author 'Cascade'

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
    'qbx_core',
    'ox_inventory',
    'ox_lib',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
