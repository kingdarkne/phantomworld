fx_version 'cerulean'
game 'gta5'

author 'Custom'
description 'Auto-give keys + unlock for admin-spawned vehicles'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qbx_core',
    'qbx_vehiclekeys',
    'ox_lib'
}
