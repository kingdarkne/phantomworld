-- Re-export dr-weathersync server APIs onto Renewed-Weathersync / qb-weathersync.

local function forwardExport(exportName)
    exports(exportName, function(...)
        return exports['qb-weathersync'][exportName](...)
    end)
end

for _, name in ipairs({
    'setWeather',
    'setTime',
    'setBlackout',
    'setTimeFreeze',
    'getBlackoutState',
    'getTimeFreezeState',
    'getWeatherState',
    'getDynamicWeather',
    'getTime',
}) do
    forwardExport(name)
end
