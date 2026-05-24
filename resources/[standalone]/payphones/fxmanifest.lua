fx_version "cerulean"
game 'gta5'
description "Tech Script 4.0 Payphones System (ur-lib removed — uses ox_target + ox_lib)"
author "Tech Script"
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

ui_page 'web/public/index.html'

files {
  'web/public/index.html'
}

client_scripts { 
  "client/**/*",
}

server_scripts { 
  "server/**/*",
  "@oxmysql/lib/MySQL.lua",
}

dependency 'ox_lib'
dependency 'oxmysql'
dependency 'ox_target'
dependency 'qbx_npwd'
