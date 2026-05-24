fx_version 'cerulean'
game 'gta5'

author 'sm-scripts'
description 'QB-Core Hunting Script'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/*.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}