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

if not Locales then
    Locales = {}
end


function GetServerLocale()
    
    if Config.Locale and Config.Locale ~= 'auto' then
        return Config.Locale
    end
    
    
    return 'en'
end


function _(key, ...)
    local locale = GetServerLocale()
    local text = key 
    
    
    if Locales and Locales[locale] and Locales[locale][key] then
        text = Locales[locale][key]
    
    elseif Locales and Locales['en'] and Locales['en'][key] then
        text = Locales['en'][key]
    end
    
    if ... then
        return string.format(text, ...)
    end
    
    return text
end
