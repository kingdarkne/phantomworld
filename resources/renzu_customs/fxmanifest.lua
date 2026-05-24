fx_version 'cerulean'
game 'gta5'

description 'Renzu Customs - Advanced Mechanic Tuning'
author 'renzuzu'
version '2.0.0'

lua54 'yes'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    '/server:5181',
    '/onesync',
    'oxmysql',
    'ox_lib',
}
