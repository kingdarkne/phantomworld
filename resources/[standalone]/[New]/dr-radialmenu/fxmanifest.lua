fx_version 'adamant'
games { 'gta5' }
lua54 'yes'

shared_scripts {
    '@dr-qbx-compat/shared.lua',
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}

client_script {
    "config.lua",
    "client_menu.lua",
	"utils.lua"
}

ui_page "nui/dist/index.html"
files {
  "nui/dist/*",
  "nui/dist/index.html",
	"nui/dist/assets/*",
}
