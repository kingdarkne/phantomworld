fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name         'dr-roofrunning'
version      '2.0.1'
description  'A multi-framework roof running'
author       'Hasib'

shared_scripts {
    '@dr-qbx-compat/shared.lua',
    'cfg.lua'
}

server_scripts {
    'sv.lua',
}

client_scripts {
    'cl.lua',
}
dependencies {
    'dr-qbx-compat',
    'qbx_core',
    'dr-npcdialogv2',
    'skillchecks',
    'j-textui'
}
ui_page "web/ui.html"

files {
	"web/ui.html",
    "web/css.css",
    "web/js.js",
    'web/fonts/*.ttf',
}
