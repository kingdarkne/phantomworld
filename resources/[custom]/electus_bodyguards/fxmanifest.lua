fx_version "cerulean"
author "@electus_scripts (ELECTUS SCRIPTS)"
version '2.0.4'
lua54 'yes'

games {
  "gta5",
}

files {
  'ui/build/index.html',
  'ui/build/**/*',
  "config/locales/*.lua"
}

ui_page 'ui/build/index.html'
-- ui_page "http://localhost:3000"

client_script {"client/**", "escrowed/client/*.lua"}

server_scripts {'@oxmysql/lib/MySQL.lua', "server/**",  "escrowed/server/*.lua",}

shared_scripts {
    "config/*.lua",
    "shared/**",
    '@ox_lib/init.lua',
}

escrow_ignore {
    'client/**',
    'server/**',
    'shared/**',
    'config/**'
}
dependency '/assetpacks'