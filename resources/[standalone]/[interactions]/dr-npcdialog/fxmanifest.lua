fx_version 'cerulean'
game 'gta5'
lua54 'yes'
escrow_ignore {
	'client/*.lua',
	'shared/*.lua'
}
shared_scripts {
    '@ox_lib/init.lua',
    '@dr-qbx-compat/shared.lua',
    'shared/config.lua'
}

dependencies {
    'dr-qbx-compat',
    'ox_lib',
    'qbx_core',
}
client_scripts {
	'@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
	'client/*.lua'
}
ui_page 'html/index.html'
files {
	'html/index.html',
	'html/style.css',
	'html/index.js'
}
dependency '/assetpacks'