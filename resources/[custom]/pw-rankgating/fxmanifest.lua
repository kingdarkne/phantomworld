fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'pw-rankgating'
description 'Phantom World — weapon rank requirements via ox_inventory hook'
version     '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}
