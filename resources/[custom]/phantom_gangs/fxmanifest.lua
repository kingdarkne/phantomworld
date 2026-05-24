fx_version 'cerulean'
game 'gta5'

author 'Phantom World'
description 'Phantom Gangs - Territory Wars & Red Zones'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/territories.lua',
    'client/wars.lua',
    'client/gang_menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/territories.lua',
    'server/wars.lua',
    'server/economy.lua',
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
