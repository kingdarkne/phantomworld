fx_version 'cerulean'
game 'gta5'

author 'Phantom World'
description 'Phantom Cops vs Robbers - PvP Arena System'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/lobby.lua',
    'client/arena.lua',
    'client/loadouts.lua',
    'client/scoreboard.lua',
    'client/spectator.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/lobby.lua',
    'server/match.lua',
    'server/teams.lua',
    'server/stats.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}
