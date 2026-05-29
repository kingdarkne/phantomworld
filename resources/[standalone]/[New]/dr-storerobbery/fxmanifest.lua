fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Dracula / Phantom World'
description 'Gun-point store clerk robbery with React NUI (QBX)'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/dist/index.html'

files {
    'html/dist/index.html',
    'html/dist/assets/*',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
