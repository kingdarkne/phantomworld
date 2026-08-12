fx_version 'bodacious'
game 'common'

-- Prebuilt dist/ — do NOT declare yarn/webpack here.
-- Those deps force endless rebuild loops and block npwd (phone) from starting.
client_script 'dist/client.js'
server_script 'dist/server.js'

files {
    'dist/ui.html'
}

ui_page 'dist/ui.html'
