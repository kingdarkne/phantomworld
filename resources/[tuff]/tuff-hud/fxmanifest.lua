fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tuff studios'
description 'Tuff Advance HUD'
version "0.1.0"

client_scripts {
	'client/functions.lua',
	'client/main.lua',
	'client/nui.lua',
	'client/keybinds.lua',
	'client/framework.lua',
	'client/stress.lua'
}

server_script 'server/main.lua'

shared_scripts {
	'shared/*.lua',
	'@ox_lib/init.lua'
}

ui_page 'nui/dist/index.html'

files {
	'nui/dist/**',
	'nui/dist/**/**',
	'assets/**'
}

dependency 'ox_lib'

escrow_ignore {
	'shared/*.lua',
	'client/framework.lua',
	'client/keybinds.lua'
}

dependency '/assetpacks'