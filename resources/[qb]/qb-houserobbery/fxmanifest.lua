fx_version 'cerulean'
fx_version 'cerulean'
game 'gta5'

author 'QBCore'
description 'QB House Robbery'

version '1.0.0'

lua54 'yes'

shared_script '@qb-lib/shared/config.lua'
shared_script '@qb-lib/shared/main.lua'

server_script 'server/main.lua'
server_script 'server/cooldown.lua'

dependency 'qb-core'
dependency 'qb-target'
