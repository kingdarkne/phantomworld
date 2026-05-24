fx_version 'cerulean'
game 'gta5'

name 'dr-admincar'
description 'Admin-only indestructible car toggle'
author 'assistant'

server_scripts {
    '@ox_lib/init.lua',
    'server.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
}

