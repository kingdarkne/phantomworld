fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'phantom_loadscreen'
author 'Phantom World'
description 'Friendly Phantom World loading screen'
version '1.0.0'

loadscreen 'html/index.html'
loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/config.js',
    'html/js/app.js',
    'html/img/logo.png',
    'html/music/background.mp3',
}

client_script 'client/main.lua'
