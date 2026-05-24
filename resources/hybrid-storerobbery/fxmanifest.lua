fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hybrid Store Robbery'
description 'Store robbery with NPC interactions, auto-popup menu, and existing script integration'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/utils.lua',
    'client/npcs.lua',
    'client/menus.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua',
    'server/utils.lua'
}

dependencies {
    'qb-core',
    'ox_target',
    'ox_lib',
    'progressbar',
    'fenix-police',
    'mz-storerobbery',
    'lation_247robbery'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
