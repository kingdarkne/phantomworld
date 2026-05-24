fx_version 'cerulean'
game 'gta5'

name 'dr-starterpack'
description 'Starter pack on first character load (QBX)'
author 'assistant'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

-- Load order: ensure `qbx_vehicles` before this in server.cfg (do not list it here — it is
-- `server_only` and some builds fail to start mixed resources that depend on it).
dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
}

