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

Config = {}

Config.CallCooldownMs = 60000

Config.JobsReceivingAlerts = {
	'lsfd',
	'ambulance',
	'ems'
}

Config.AlsoSendAlertToVictimIfAlone = true

Config.CreateMapBlipForEMS = true
Config.BlipSprite = 153
Config.BlipColor = 1
Config.BlipFadeMs = 120000

Config.DisableControlsWhileDown = true

Config.ReviveHealth = 200

Config.UseServerValidatedPosition = true
Config.ServerCallCooldownMs = 60000

Config.RestrictCommands = false
Config.AcePermissionAdmin = 'command.nextdeath'

return Config
