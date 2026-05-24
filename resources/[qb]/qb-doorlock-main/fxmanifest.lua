-- Wrapper so FiveM finds this resource (inner manifest is in qb-doorlock-main/)
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'qb-doorlock-main/html/index.html'

shared_scripts {
    'qb-doorlock-main/config.lua',
    'qb-doorlock-main/configs/*.lua',
    '@qbx_core/shared/locale.lua',
    'qb-doorlock-main/locales/en.lua',
    'qb-doorlock-main/locales/*.lua'
}

server_script 'qb-doorlock-main/server/main.lua'
client_script 'qb-doorlock-main/client/main.lua'

files {
    'qb-doorlock-main/html/*.html',
    'qb-doorlock-main/html/*.js',
    'qb-doorlock-main/html/*.css',
    'qb-doorlock-main/html/sounds/*.ogg',
}
