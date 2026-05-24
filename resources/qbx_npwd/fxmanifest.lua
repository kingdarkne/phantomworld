fx_version 'cerulean'
game 'gta5'

description 'A simple bridge resource for Qbox Compatibility for NPWD'
version '1.0.0'
repository 'https://github.com/Qbox-Project/qbx_npwd'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

lua54 'yes'
provide 'qb-npwd'

-- NPWD must be running first so exports.npwd exists when this resource starts.
dependency 'npwd'
dependency 'oxmysql'
dependency 'qbx_core'
dependency 'ox_inventory'
