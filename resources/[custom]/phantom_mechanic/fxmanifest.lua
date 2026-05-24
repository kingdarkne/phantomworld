fx_version 'cerulean'
game 'gta5'

author 'Phantom World'
description 'Phantom Mechanic - Custom Orders & Tablet System'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
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
