fx_version 'cerulean'
game 'gta5'

author 'Tonybyn_Mp4'
description 'Burgershot Job (QBX + ox_inventory)'
repository 'https://github.com/TonybynMp4/y_burgershot'
version '1.3.4'

ox_lib 'locale'
shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua'
}

server_scripts {
	'server/main.lua'
}

files {
    'locales/*.json',
    'config/client.lua',
    'config/shared.lua'
}

dependencies {
    'qbx_core',
    'ox_inventory',
    'ox_lib',
    'ox_target',
}

lua54 'yes'
