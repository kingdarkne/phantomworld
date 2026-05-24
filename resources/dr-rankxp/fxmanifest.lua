fx_version 'cerulean'
game 'gta5'

name 'dr-rankxp'
description 'Central XP hooks for XNLRankBar + QBX'
author 'assistant'

lua54 'yes'

shared_scripts {
    '@dr-qbx-compat/shared.lua',
    '@ox_lib/init.lua',
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
    'XNLRankBar',
}

