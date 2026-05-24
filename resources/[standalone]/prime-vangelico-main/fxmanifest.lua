-- Wrapper so FiveM finds this resource (inner content in prime-vangelico-main/)
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    'locale_stub.lua',
    'prime-vangelico-main/locales/en.lua',
    'prime-vangelico-main/config.lua'
}

client_scripts {
    'prime-vangelico-main/client/main.lua',
}

server_scripts {
    'prime-vangelico-main/server/main.lua',
}
