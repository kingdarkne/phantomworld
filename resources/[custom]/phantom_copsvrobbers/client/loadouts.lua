-- Loadout selection UI
function OpenLoadoutMenu(team)
    local loadoutKey = team == 'cops' and { 'cop', 'swat' } or { 'robber', 'heavy' }
    local options = {}

    for _, key in ipairs(loadoutKey) do
        local loadout = Config.Loadouts[key]
        table.insert(options, {
            title = key:upper(),
            description = table.concat(GetWeaponNames(loadout.weapons), ', '),
            onSelect = function()
                lib.notify({ title = 'Loadout Selected', description = key:upper(), type = 'success' })
            end
        })
    end

    lib.registerContext({ id = 'cvr_loadout', title = 'Select Loadout', options = options })
    lib.showContext('cvr_loadout')
end

function GetWeaponNames(weapons)
    local names = {}
    for _, w in ipairs(weapons) do
        table.insert(names, w.name:gsub('weapon_', ''):upper())
    end
    return names
end
