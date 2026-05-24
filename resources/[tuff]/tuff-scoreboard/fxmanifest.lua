fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tuff Scripts'
version 'v 0.0.2'
description 'Tuff Advanced Scoreboard'

ui_page 'web/dist/index.html'

files {
	'web/dist/**',
	'web/dist/**/**',
	'dui/dist/**',
	'dui/dist/**/**',
	'assets/**',
	'assets/**/**'
}

client_scripts {
	'client/functions.lua',
	'client/main.lua',
	'client/framework.lua'
}

server_scripts {
	'server/functions.lua',
	'server/main.lua',
	'server/framework.lua'
	-- '@oxmysql/lib/MySQL.lua'
}

shared_scripts {
	'shared/*.lua',
	'@ox_lib/init.lua'
}

escrow_ignore {
	'shared/*.lua',
}

dependency '/assetpacks'