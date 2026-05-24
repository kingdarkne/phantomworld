fx_version 'cerulean'
game 'gta5'

author 'dracula'
description 'Dracula Scripts'

ui_page "nui/index.html"

shared_scripts {
    '@ox_lib/init.lua',
    'shared/sh_config.lua',
    'shared/qbx_compat.lua',
    'locale.lua',
    'locales/en.lua', 
}

client_scripts {
    'client/**/cl_*.lua',
    'shared/sh_commands.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**/sv_*.lua',
}

files {
    "nui/index.html",
    "nui/js/**.js",
    "nui/css/**.css",
    "nui/webfonts/*.css",
    "nui/webfonts/*.otf",
    "nui/webfonts/*.ttf",
    "nui/webfonts/*.woff2",
}

exports {
    'CreateLog',
    'ToggleDev',
}

server_exports {
    'CreateLog'
} 

dependencies {
    'oxmysql',
    'qbx_core',
    'ox_lib',
    'ox_inventory'
}

lua54 'yes'