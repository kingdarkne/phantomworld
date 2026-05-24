---@param locale string
local function LoadLocaleFile(locale)
    local rawLocales = LoadResourceFile(GetCurrentResourceName(), "config/locales/" .. locale .. ".lua")

    if not rawLocales then
        return {}
    end

    local fn, err = load(rawLocales)

    if not fn or err then
        return {}
    end

    ---@type table
    local locales = fn()

    local function FormatLocales(localeTable, prefix)
        prefix = prefix or ""

        for k, v in pairs(localeTable) do
            if type(v) == "table" and #v == 0 then
                FormatLocales(v, prefix .. k .. ".")
            else
                locales[prefix .. k] = v
            end
        end
    end

    FormatLocales(locales)

    return locales
end

if type(Config.locale) ~= "string" then
    Config.locale = "en"
end

local locales = LoadLocaleFile(Config.locale)

if Config.locale ~= "en" then
    local fallbackLocales = LoadLocaleFile("en")

    for path, locale in pairs(fallbackLocales) do
        if not locales[path] then
            locales[path] = locale
        end
    end
end

function L(path, args)
    local translation = locales[path] or path

    if args then
        for k, v in pairs(args) do
            local escapedValue = tostring(v):gsub("%%", "%%%%")

            translation = translation:gsub("{" .. k .. "}", escapedValue)
        end
    end

    return translation
end

function GetAllLocales()
    return locales
end