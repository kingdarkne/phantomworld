fx_version 'cerulean'
game 'gta5'
lua54 'yes'
escrow_ignore {
	'shared/*.lua',
	'client/*.lua'
}
shared_scripts {
    '@dr-qbx-compat/shared.lua',
    'shared/*.lua'
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}
client_scripts {
	'client/*.lua'
}
ui_page 'html/index.html'
files {
	'html/index.html',
	'html/style.css',
	'html/index.js'
}
exports {
    'displayTextUI',
    'hideTextUI',
	'changeText',
	'create3DTextUI',
	'update3DTextUI',
	'create3DTextUIOnPlayers',
	'delete3DTextUIOnPlayers',
	'delete3DTextUI'
}
dependency '/assetpacks'