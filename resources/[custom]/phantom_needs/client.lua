-- Phantom Needs - eat/drink still work; empty hunger/thirst/sleep cannot kill.

local needKeys = { 'hunger', 'thirst', 'sleep', 'fatigue', 'energy' }

local function needsAreEmpty()
    local state = LocalPlayer.state
    for i = 1, #needKeys do
        local key = needKeys[i]
        local value = state[key]
        if value ~= nil and value <= 0 then
            return true
        end
    end
    return false
end

-- Safety net if another resource still drains health from needs.
CreateThread(function()
    if not Config.DisableNeedDamage then return end

    while true do
        Wait(1000)

        if not cache.ped or cache.ped == 0 then goto continue end
        if LocalPlayer.state.isDead then goto continue end
        if not needsAreEmpty() then goto continue end

        local health = GetEntityHealth(cache.ped)
        if health > 0 and health <= 101 then
            SetEntityHealth(cache.ped, 102)
        end

        ::continue::
    end
end)

-- Keep optional sleep/fatigue statebags from sticking at negative values.
CreateThread(function()
    while true do
        Wait(5000)
        if Config.MinHungerThirst <= 0 then goto continue end

        local state = LocalPlayer.state
        if (state.hunger or 100) < Config.MinHungerThirst then
            LocalPlayer.state:set('hunger', Config.MinHungerThirst, true)
        end
        if (state.thirst or 100) < Config.MinHungerThirst then
            LocalPlayer.state:set('thirst', Config.MinHungerThirst, true)
        end

        ::continue::
    end
end)

print('^2[phantom_needs]^7 Need damage disabled — food and drink still work')
