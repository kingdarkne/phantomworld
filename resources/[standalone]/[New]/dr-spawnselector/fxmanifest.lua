fx_version 'cerulean'
game 'gta5'
shared_scripts {
	'@dr-qbx-compat/shared.lua',
	'config.lua'
}
dependencies {
	'dr-qbx-compat',
	'qbx_core',
}
escrow_ignore 'config.lua'
client_script 'c.lua'
server_script 's.lua'
ui_page 'html/index.html'
files {
	'html/index.html',
	'html/style.css',
	'html/index.js',
    'html/files/*.png',
    'html/files/*.jpg',
    'html/files/*.jfif',
	'html/fonts/*.otf',
	'html/fonts/*.ttf'
}