fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Custom NPC Store Robbery'
description 'Store robbery with NPC ped interactions and vault hacking'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/utils.lua',
    'client/npcs.lua',
    'client/main.lua',
    'client/hacking.lua'
}

server_scripts {
    'server/main.lua',
    'server/utils.lua'
}

dependencies {
    'qb-core',
    'ox_target',
    'ox_lib'
}

data_file 'INTERIOR_PROXY_ORDER_FILE' 'interiorproxies.meta'

files {
    'interiorproxies.meta'
}
