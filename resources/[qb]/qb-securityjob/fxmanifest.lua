fx_version 'cerulean'
game 'gta5'

name 'qb-securityjob'
description 'QB-Security-Job edited Garbage Job by Kazashimo'
version '1.2.0'

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/shared/locale.lua',
	'qb-securityjob/shared/qbx_compat.lua',
	'qb-securityjob/locales/en.lua',
	'qb-securityjob/locales/*.lua',
	'qb-securityjob/config.lua'
}

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
	'qb-securityjob/client/main.lua'
}
server_script 'qb-securityjob/server/main.lua'

lua54 'yes'
