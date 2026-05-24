fx_version 'cerulean'
game 'gta5'

author 'Phantom World'
description 'Phantom Events - Admin Events, Money Drops, Free Cars, & More'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/money_drop.lua',
    'client/free_cars.lua',
    'client/bonus_events.lua',
    'client/treasure_hunt.lua',
    'client/lottery.lua',
    'client/admin_panel.lua',
    'client/notifications.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/events.lua',
    'server/permissions.lua',
    'server/payouts.lua',
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
