fx_version 'cerulean'
game 'gta5'

author 'Phantom World'
description 'Phantom Heists - Banks, Jewelry & Armored Trucks'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/minigames.lua',
    'client/loot.lua',
    'client/police_dispatch.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/police.lua',
    'server/payouts.lua',
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
