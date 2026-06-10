fx_version 'cerulean'
game 'gta5'

author 'Phantom World - Wanted System'
description 'Simple QBCore wanted level/points system with basic auto-flagging'
version '1.0.1'

shared_script '@ox_lib/init.lua'

dependencies {
    'ox_lib',
    'qbx_core',
    'fenix-police',
}

server_script 'server.lua'
client_script 'client.lua'

