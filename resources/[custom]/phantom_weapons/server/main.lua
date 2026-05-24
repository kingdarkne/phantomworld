-- Phantom Weapons - Server Main

-- Buy weapon
RegisterNetEvent('phantom_weapons:server:buyWeapon', function(weaponName)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local price = Config.WeaponPrices[weaponName] or 1000

    if Player.PlayerData.money.cash < price then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Insufficient Funds', description = 'Need $' .. price, type = 'error' })
        return
    end

    -- Check license
    if Config.RequireLicense and not Player.PlayerData.metadata.weaponlicense then
        TriggerClientEvent('ox_lib:notify', src, { title = 'No License', description = 'Need a weapon license', type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', price, 'weapon-purchase')
    Player.Functions.AddItem(weaponName, 1)

    TriggerClientEvent('ox_lib:notify', src, { title = 'Weapon Purchased', description = weaponName:gsub('weapon_', ''):upper(), type = 'success' })
end)

-- Buy ammo
RegisterNetEvent('phantom_weapons:server:buyAmmo', function(weaponName, amount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local ammoType = GetAmmoTypeForWeapon(weaponName)
    local price = (Config.AmmoPrices[ammoType] or 50) * amount

    if Player.PlayerData.money.cash < price then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Insufficient Funds', type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', price, 'ammo-purchase')
    Player.Functions.AddItem(ammoType .. '_ammo', 24 * amount)

    TriggerClientEvent('ox_lib:notify', src, { title = 'Ammo Purchased', description = (24 * amount) .. ' rounds', type = 'success' })
end)

-- Buy weapon tint
RegisterNetEvent('phantom_weapons:server:buyTint', function(weaponName, tintId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local tint = Config.WeaponTints.colors[tintId + 1]
    if not tint then return end

    if Player.PlayerData.money.cash < tint.price then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Insufficient Funds', type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', tint.price, 'tint-purchase')

    -- Apply tint
    TriggerClientEvent('phantom_weapons:client:applyTint', src, weaponName, tintId)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Tint Applied', description = tint.name, type = 'success' })
end)

-- Buy attachment
RegisterNetEvent('phantom_weapons:server:buyAttachment', function(weaponName, attachment)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local price = Config.Attachments.prices[attachment] or 500

    if Player.PlayerData.money.cash < price then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Insufficient Funds', type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', price, 'attachment-purchase')
    TriggerClientEvent('phantom_weapons:client:applyAttachment', src, weaponName, attachment)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Attachment Added', type = 'success' })
end)

-- Buy weapon license
RegisterNetEvent('phantom_weapons:server:buyWeaponLicense', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    if Player.PlayerData.metadata.weaponlicense then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Already Have License', type = 'error' })
        return
    end

    if Player.PlayerData.money.cash < Config.WeaponLicensePrice then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Need $' .. Config.WeaponLicensePrice, type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', Config.WeaponLicensePrice, 'weapon-license')
    Player.Functions.SetMetaData('weaponlicense', true)

    TriggerClientEvent('ox_lib:notify', src, { title = 'License Acquired', description = 'You can now buy weapons!', type = 'success' })
end)

-- Weapon locker store
RegisterNetEvent('phantom_weapons:server:storeWeapon', function(weaponName)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    Player.Functions.RemoveItem(weaponName, 1)
    -- Store in locker (would need locker DB table)
    MySQL.insert('INSERT INTO phantom_weapon_locker (citizenid, weapon_name, stored_at) VALUES (?, ?, ?)', {
        Player.PlayerData.citizenid, weaponName, os.time()
    })

    TriggerClientEvent('ox_lib:notify', src, { title = 'Weapon Stored', description = weaponName:gsub('weapon_', ''):upper(), type = 'success' })
end)

-- Weapon locker retrieve
RegisterNetEvent('phantom_weapons:server:retrieveWeapons', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local weapons = MySQL.query.await('SELECT * FROM phantom_weapon_locker WHERE citizenid = ?', {
        Player.PlayerData.citizenid
    })

    if weapons and #weapons > 0 then
        for _, w in ipairs(weapons) do
            Player.Functions.AddItem(w.weapon_name, 1)
        end
        MySQL.update('DELETE FROM phantom_weapon_locker WHERE citizenid = ?', { Player.PlayerData.citizenid })
        TriggerClientEvent('ox_lib:notify', src, { title = 'Weapons Retrieved', description = #weapons .. ' weapons', type = 'success' })
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Locker Empty', type = 'error' })
    end
end)

-- Helper functions
function GetAmmoTypeForWeapon(weaponName)
    if string.find(weaponName, 'pistol') then return 'pistol' end
    if string.find(weaponName, 'smg') or string.find(weaponName, 'micro') then return 'smg' end
    if string.find(weaponName, 'rifle') or string.find(weaponName, 'carbine') then return 'rifle' end
    if string.find(weaponName, 'shotgun') then return 'shotgun' end
    if string.find(weaponName, 'sniper') then return 'sniper' end
    if string.find(weaponName, 'mg') or string.find(weaponName, 'minigun') then return 'heavy' end
    return 'pistol'
end

-- DB Init
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_weapon_locker (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) NOT NULL,
                weapon_name VARCHAR(50) NOT NULL,
                stored_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_citizenid (citizenid)
            )
        ]])
        print('^2[Phantom Weapons]^7 Server loaded')
    end
end)
