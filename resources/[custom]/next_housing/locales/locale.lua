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
Locales = {}
local TranslationCache = {}

function GetServerLocale()
    if getCurrentLocale and type(getCurrentLocale) == 'function' then
        return getCurrentLocale()
    end
    return Config.DefaultLocale or 'en'
end


function _(key, ...)
    local locale = Config.DefaultLocale or 'en'
    
    if getCurrentLocale and type(getCurrentLocale) == 'function' then
        locale = getCurrentLocale()
    else
        locale = GetServerLocale()
    end
    
    local text = Locales[locale] and Locales[locale][key] or Locales['en'][key] or key
    
    if ... then
        return string.format(text, ...)
    end
    
    return text
end

function getTranslationsFor(locale)
    local selectedLocale = locale or Config.DefaultLocale or 'en'
    local cached = TranslationCache[selectedLocale]
    if cached then
        return cached
    end

    local translations = {}

    if Locales['en'] then
        for key, value in pairs(Locales['en']) do
            translations[key] = value
        end
    end

    if Locales[selectedLocale] then
        for key, value in pairs(Locales[selectedLocale]) do
            translations[key] = value
        end
    end

    if next(translations) then
        TranslationCache[selectedLocale] = translations
    end

    return translations
end
