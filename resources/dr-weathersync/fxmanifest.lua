fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dr-weathersync'
description 'Compatibility shim for dr-weathersync event/export names (backend: Renewed-Weathersync)'
version '1.0.0'

dependencies {
    'Renewed-Weathersync',
}

client_script 'client.lua'
server_script 'server.lua'
