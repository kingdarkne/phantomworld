fx_version 'cerulean'
game 'gta5'

name 'XNLRankBar'
description 'XP Ranking System for FiveM (QBCore) – wrapper for inner XNLRankBar folder'
author 'milotiro95 / VenomXNL'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'XNLRankBar/client/main.lua'
}

server_scripts {
    'XNLRankBar/server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

-- Re‑export the same functions as the inner resource
export 'Exp_XNL_SetInitialXPLevels'
export 'Exp_XNL_AddPlayerXP'
export 'Exp_XNL_RemovePlayerXP'
export 'Exp_XNL_GetCurrentPlayerXP'
export 'Exp_XNL_GetLevelFromXP'
export 'Exp_XNL_GetCurrentPlayer'
export 'Exp_XNL_GetCurrentPlayerLevel'
export 'Exp_XNL_GetXPCeilingForLevel'
export 'Exp_XNL_GetXPFloorForLevel'

