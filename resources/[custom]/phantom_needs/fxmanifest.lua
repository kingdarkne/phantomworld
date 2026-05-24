fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'phantom_needs'
description 'Phantom World - needs decay without starvation/dehydration death'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
