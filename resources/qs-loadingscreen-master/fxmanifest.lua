fx_version 'cerulean'
game 'gta5'

description 'qs-loadingscreen'
author 'Quasar Store'
version '1.0.0'

client_script 'client.lua'

files {
  'web/build/**/*',
}

loadscreen 'web/build/index.html'

loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

lua54 'yes'
