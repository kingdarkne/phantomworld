fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name         'dr-ammorobbery'
version      '2.0.0'
description  'A multi-framework  Ammo Robbery'
author       'Hasib'

shared_scripts {
    '@ox_lib/init.lua',
    'cfg.lua'
}

server_scripts {
    'sv.lua',
    '@oxmysql/lib/MySQL.lua',

}

client_scripts {
    'cl.lua',
}
dependencies {
    'jomidar-ui'
}
