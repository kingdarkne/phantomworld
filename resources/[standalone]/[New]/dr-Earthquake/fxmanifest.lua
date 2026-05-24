fx_version 'adamant'
game 'gta5'

Author 'Jakrino'
description 'Jakrino Earthquake V1'
version '1.0'

ui_page 'web/index.html'

shared_scripts { 
	'@dr-qbx-compat/shared.lua',
	'config.lua',
    'locales/*.lua',
}

dependencies {
	'dr-qbx-compat',
	'qbx_core',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'web/index.html',
    'web/main.js',
    'web/style.css',
    'web/fonts/*.*',
    'web/images/*.*',
}

escrow_ignore {
    'config.lua',
    'client/*.lua',
    'server/*.lua',
    'locales/*.lua',
    'web/index.html',
    'web/main.js',
    'web/style.css',
    'web/fonts/*.*',
    'web/images/*.*',
}

lua54 'yes'
dependency '/assetpacks'