fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Phantom World'
description 'Phantom Core - Custom UI, Vehicle, Player, Economy, and Game Mechanics'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua',
    'shared/config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/core.lua',
    'client/ui/notifications.lua',
    'client/ui/progress.lua',
    'client/ui/menu.lua',
    'client/ui/dialog.lua',
    'client/vehicles/spawner.lua',
    'client/vehicles/garage.lua',
    'client/vehicles/tuning.lua',
    'client/vehicles/fuel.lua',
    'client/player/emotes.lua',
    'client/player/interactions.lua',
    'client/player/actions.lua',
    'client/player/radio.lua',
    'client/help_system.lua',
    'client/economy/banking.lua',
    'client/economy/shops.lua',
    'client/economy/jobs.lua',
    'client/economy/tax.lua',
    'client/mechanics/skills.lua',
    'client/mechanics/inventory.lua',
    'client/mechanics/housing.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/framework.lua',
    'server/economy/banking.lua',
    'server/economy/shops.lua',
    'server/economy/jobs.lua',
    'server/economy/tax.lua',
    'server/mechanics/skills.lua',
    'server/mechanics/housing.lua',
    'server/vehicles/garage.lua'
}

ui_page 'ui/dist/index.html'

files {
    'ui/dist/index.html',
    'ui/dist/assets/*.css',
    'ui/dist/assets/*.js',
    'ui/dist/assets/*.png',
    'ui/images/*.png',
    'ui/dist/assets/*.ttf',
    'ui/dist/assets/*.otf'
}
