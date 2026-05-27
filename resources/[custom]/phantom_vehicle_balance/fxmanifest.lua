fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Phantom World'
description 'Category-based vehicle performance balancing'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'

dependencies {
    'ox_lib',
    'qbx_core'
}
