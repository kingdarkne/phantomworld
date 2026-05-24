if Config.framework == 'qbx' then

    -- Commented out: qbx_core already provides this callback
    -- lib.callback.register('qbx_core:server:getCharacters', function(source)
    --     local license = GetPlayerIdentifierByType(source, 'license')
    --     license = license and license:gsub('license:', '')

    --     if not license then
    --         print('[Multicharacter] ERROR: No license identifier found for player', source)
    --         return {}, 0
    --     end

    --     local result = MySQL.query.await('SELECT * FROM players WHERE license = ?', { license })
    --     local characters = {}
    --     local count = 0

    --     if result then
    --         for _, v in pairs(result) do
    --             v.charinfo = json.decode(v.charinfo)
    --             v.money = json.decode(v.money)
    --             v.job = json.decode(v.job)
    --             characters[#characters + 1] = v
    --             count = count + 1
    --         end
    --     end

    --     print('[Multicharacter] Found', count, 'characters for player', source)
    --     return characters, count
    -- end)
    
    lib.callback.register('IV:GetAllCharacters', function(source)
        local plyChars = {}
        local result = MySQL.query.await('SELECT * FROM players')

        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)
            plyChars[#plyChars + 1] = result[i]
        end

        return plyChars
    end)


    lib.callback.register("IV:GetSkin", function(source, cid)
        local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', { cid, 1 })

        if result[1] then
            return result[1].model, result[1].skin
        end
    end)

    lib.callback.register('IV:IsAdmin', function(source)
        return IsPlayerAceAllowed(source, 'command')
    end)

    -- Commented out: qbx_core already provides this callback
    -- lib.callback.register('qbx_core:server:loadCharacter', function(source, citizenid)
    --     print('[Multicharacter] Loading character', citizenid, 'for player', source)
    --     -- Use qbx_core's method to load the character
    --     local Player = exports.qbx_core:GetPlayer(source)
    --     if Player then
    --         -- Already logged in, just return success
    --         return true
    --     end
    --     -- qbx_core handles the actual loading
    --     return true
    -- end)

    -- Commented out: qbx_core already provides this callback
    -- lib.callback.register('qbx_core:server:createCharacter', function(source, data)
    --     print('[Multicharacter] Creating character for player', source, 'slot', data.cid)

    --     local license = GetPlayerIdentifierByType(source, 'license')
    --     license = license and license:gsub('license:', '')

    --     if not license then
    --         print('[Multicharacter] ERROR: No license identifier for character creation')
    --         return nil
    --     end

    --     -- Generate citizenid
    --     local citizenid = exports.qbx_core:GenerateCitizenID()

    --     -- Build charinfo
    --     local charinfo = {
    --         firstname = data.firstname,
    --         lastname = data.lastname,
    --         birthdate = data.birthdate,
    --         gender = data.gender,
    --         nationality = data.nationality,
    --         cid = data.cid
    --     }

    --     -- Default money
    --     local money = {
    --         cash = 0,
    --         bank = 5000
    --     }

    --     -- Default job
    --     local job = {
    --         name = 'unemployed',
    --         label = 'Unemployed',
    --         isboss = false,
    --         grade = {
    --             name = 'Freelancer',
    --             level = 0
    --         }
    --     }

    --     -- Insert into database
    --     MySQL.insert.await('INSERT INTO players (license, citizenid, charinfo, money, job, position) VALUES (?, ?, ?, ?, ?, ?)', {
    --         license,
    --         citizenid,
    --         json.encode(charinfo),
    --         json.encode(money),
    --         json.encode(job),
    --         json.encode({x = -1042.0, y = -2746.0, z = 21.0, w = 0.0})
    --     })

    --     print('[Multicharacter] Character created successfully:', citizenid)

    --     -- Return the new character data
    --     return {
    --         citizenid = citizenid,
    --         charinfo = charinfo,
    --         money = money,
    --         job = job
    --     }
    -- end)

end
