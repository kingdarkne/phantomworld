fx_version 'cerulean'
game 'gta5'

description 'World Events Panel - Trigger/view server events'
version '1.0.0'
author 'Cascade'

shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
