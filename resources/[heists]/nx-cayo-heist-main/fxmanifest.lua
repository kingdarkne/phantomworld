-- Wrapper so FiveM finds this resource (inner content in nx-cayo-heist-main/)
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'nx-cayo-heist-main/client/main.lua',
    'nx-cayo-heist-main/client/target.lua'
}

server_scripts {
    'nx-cayo-heist-main/server/main.lua'
}

shared_scripts {
    'nx-cayo-heist-main/config.lua'
}
