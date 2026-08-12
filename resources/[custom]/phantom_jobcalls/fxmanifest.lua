fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'phantom_jobcalls'
author 'Phantom World'
description 'GTA Online-style NPC phone contracts (hitman, robbery, police tips)'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
