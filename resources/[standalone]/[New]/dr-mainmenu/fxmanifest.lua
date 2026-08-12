fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Phantom World'
description 'Phantom World – GTAO-style Interaction Hub'
version '2.0.0'

shared_scripts { '@ox_lib/init.lua' }

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

client_script 'client.lua'
server_script 'server.lua'

dependency 'ox_lib'
