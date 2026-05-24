fx_version 'cerulean'
games {'gta5'}
author "Dracula"
description 'Radar Gun Script for FiveM'
lua54 'yes'
ui_page "html/index.html"

files{
	-- "**/weaponcomponents.meta", -- not in pack; comment out to avoid warning
	"**/weaponarchetypes.meta",
	"**/weaponanimations.meta",
	"**/pedpersonality.meta",
	"**/weapons.meta",
	"html/index.html",
	"html/js/jquery-3.6.0.min.js",
	"html/img/radargun.png",
	"html/img/scope.png",
	"html/js/listener.js",
	"html/style.css",
}
escrow_ignore {
	'config.lua'
}

-- data_file 'WEAPONCOMPONENTSINFO_FILE' '**/weaponcomponents.meta' -- file not in pack
data_file 'WEAPON_METADATA_FILE' '**/weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE' '**/weaponanimations.meta'
data_file 'PED_PERSONALITY_FILE' '**/pedpersonality.meta'
data_file 'WEAPONINFO_FILE' '**/weapons.meta'

client_scripts {
 	'cl_weaponNames.lua',
	'config.lua',
	'client.lua',
}