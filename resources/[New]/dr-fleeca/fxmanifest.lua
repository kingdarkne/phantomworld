fx_version "adamant"
game "gta5"

shared_scripts {
    '@dr-qbx-compat/shared.lua',
}

dependencies {
    'dr-qbx-compat',
    'qbx_core',
}

client_scripts {"utk.lua", "client.lua"}
server_scripts {"utk.lua", "server.lua"}
lua54 'yes'
escrow_ignore {
    'client.lua',
    'server.lua',
    "utk.lua"
}
