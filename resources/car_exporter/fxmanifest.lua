fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Custom'
description 'Car Exporter - Export vehicles for cash with rotating hot cars'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core'
}
