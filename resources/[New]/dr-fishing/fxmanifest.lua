fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name         'dr-fishing'
version      '1.1.2'
description  'A multi-framework fishing'
author       'Hasib'

shared_scripts {
    '@dr-qbx-compat/shared.lua',
    'cfg.lua'
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}

server_scripts {
    'sv.lua',
}

client_scripts {
    'cl.lua',
    'nui.lua'
}

ui_page "web/ui.html"

files {
	"web/ui.html",
    "web/css.css",
    "web/js.js",
    'web/fonts/*.ttf',
}
dependencies {
    'jomidar-ui'
}

escrow_ignore {
    'cfg.lua',
}