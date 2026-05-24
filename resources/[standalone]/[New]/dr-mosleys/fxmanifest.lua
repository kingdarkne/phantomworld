fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name         'dr-mosleys'
version      '1.0.0'
description  'A multi-framework mosleys script'
author       'Hasib'

shared_scripts {
    '@dr-qbx-compat/shared.lua',
    'cfg.lua'
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}

server_scripts {
    'sv.lua'
}

client_scripts {
    'cl.lua'
}

