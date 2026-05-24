fx_version 'cerulean'
game 'gta5'

author 'Tuff Scripts'
description 'Tuff Advance Loading Screen'
version "0.0.6"

client_script 'client.lua'
server_script 'server.lua'
shared_script 'settings.lua'

loadscreen 'dist/index.html'
loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

files {
    'config.json',
    'dist/index.html',
    'dist/assets/**',
    'assets/**/**',
}

escrow_ignore {
    -- opened files
    'client.lua',
    'config.json',
    'server.lua',
    'settings.lua',
}

dependency '/assetpacks'