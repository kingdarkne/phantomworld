fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Allows players to collect garbage for money'
version '1.2.0'

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/shared/locale.lua',
	'shared/qbx_compat.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua'
}

client_script {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
	'client/main.lua'
}

server_script 'server/main.lua'

dependencies {
	'qbx_core',
	'ox_lib',
}
