fx_version 'cerulean'
game 'gta5'
author 'Phantom World'
description 'AI EMS dispatch when no medics are online'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

dependencies {
    'ox_lib',
}
