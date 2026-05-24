--[[
  ------------------------------------------------------------------------------------------------
    Next Housing - Complete housing system
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
    
    Documentation: https://www.nextcorestudio.com/docs/next-housing/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-housing/
    Tebex: https://junnho.tebex.io/package/7057755

--------------------------------------------------------------------------------------------------
]]
Config = {}


Config.DefaultLocale = 'en'


Config.Debug = false


Config.UseAdmin = true


Config.UseItem = false


Config.AcePermissionAdmin = 'command.nexthousing'



Config.AccessCommand = {
    ESX = {
        ['user'] = false,
        ['admin'] = true,
        ['superadmin'] = true,
        ['god'] = true,
        ['moderator'] = true,
        ['helper'] = true
    },
    QBCore = {
        ['admin'] = true,
        ['god'] = true,
        ['moderator'] = true,
        ['helper'] = true,
        ['staff'] = true,
        ['management'] = true
    },
    Qbox = {
        ['admin'] = true,
        ['god'] = true,
        ['moderator'] = true,
        ['helper'] = true,
        ['staff'] = true,
        ['management'] = true
    }
}


Config.GHoldMs = 600


Config.CommissionRate = 5.00


Config.AgencyGetsAllMoney = true



