--[[
  ------------------------------------------------------------------------------------------------
    Next Death - Advanced death system
  ------------------------------------------------------------------------------------------------
  _   _ ________   _________ _____ ____  _____  ______ 
 | \ | |  ____\ \ / /__   __/ ____/ __ \|  __ \|  ____|
 |  \| | |__   \ V /   | | | |   | |  | | |__) | |__   
 | . ` |  __|   > <    | | | |   | |  | |  _  /|  __|  
 | |\  | |____ / . \   | | | |___| |__| | | \ \| |____ 
 |_| \_|______/_/ \_\  |_|  \_____\____/|_|  \_\______|                                                       
                                                       
  ------------------------------------------------------------------------------------------------
    Created for Nextcore Studio by Junnho
  ------------------------------------------------------------------------------------------------
    
    Author: Nextcore Studio
    Copyright © 2025 Junnho. All rights reserved.
    Copyright © 2025 Nextcore Studio. All rights reserved.
    License: EULA (see LICENSE file)
    
    Documentation: https://www.nextcorestudio.com/docs/next-death/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-death/?from=homepage
    Tebex: https://nextcorestudio.tebex.io/package/7057654

--------------------------------------------------------------------------------------------------
]]

fx_version 'cerulean'
game 'gta5'

name 'Next Death'
author 'Nextcore Studio'
version '1.4.2'
description 'Advanced death system'

lua54 'yes'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/styles.css',
    'nui/script.js',
    'nui/admin.css',
    'nui/admin.js'
}

escrow_ignore {
    'config.lua',
    'locales/*.lua',
}

shared_scripts {
    'config.lua',
    'locales/locale.lua',
    'locales/en.lua',
    'locales/fr.lua',
    'locales/es.lua',
    'locales/de.lua',
    'locales/pt.lua',
    'locales/ru.lua',
    'locales/tr.lua',
    'locales/ar.lua',
    'locales/ja.lua',
    'locales/zh.lua',
    'locales/hi.lua',
    'locales/bn.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database/manager.lua',
    'server/main.lua'
}

dependency '/assetpacks'