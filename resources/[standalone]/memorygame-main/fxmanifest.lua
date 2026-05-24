-- Wrapper so FiveM finds this resource (inner content in memorygame-main/)
fx_version 'adamant'
game 'gta5'

client_scripts {
  'memorygame-main/client/main.lua',
}

ui_page 'memorygame-main/html/index.html'

files {
  'memorygame-main/html/index.html',
  'memorygame-main/html/style.css',
  'memorygame-main/html/app.js'
}
