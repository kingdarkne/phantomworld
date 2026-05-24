fx_version 'cerulean'
game 'gta5'

name 'dr-ownervest'
description 'Free owner/admin vest using default GTA components'
author 'assistant'

shared_script '@ox_lib/init.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'qbx_core',
}

