fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'phantom_dashboard'
author 'Phantom World'
description 'Compact Phantom World info strip + Discord status bridge'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
    'server/discord_dm.lua',
    'server/alerts.lua',
    'server/discord.lua',
    'server/http.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'qbx_core',
    'ox_lib',
}
