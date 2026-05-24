fx_version 'cerulean'

game 'gta5'

shared_scripts {
    '@dr-qbx-compat/shared.lua',
    '@ox_lib/init.lua',
    'locale_stub.lua',
    'locales/en.lua',
    'config.lua',
}

client_scripts{
    'client/*.lua',
}

server_scripts{
    'server/*.lua',
}

dependencies {
    'dr-qbx-compat',
    'ox_lib',
    'ox_inventory',
    'qbx_core',
}

exports {
    'getTrade'
}
