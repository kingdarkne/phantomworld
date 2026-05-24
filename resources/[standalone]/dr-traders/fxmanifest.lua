fx_version 'cerulean'

game 'gta5'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/locale_stub.lua',
    'locales/en.lua',
    'config.lua',
}

client_scripts{
    'client/*.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
}

-- server_scripts{ 'server/*.lua' } -- no server folder in pack; remove if you add server scripts
