if Config.framework == 'qbx' then
    -- Ensure QBX global is available
    QBX = QBX or exports.qbx_core:GetCoreObject()
    
    IsplayerLoaded = function()
        local playerData = (QBX and QBX.PlayerData) or exports.qbx_core:GetPlayerData()
        return playerData and playerData.charinfo and true or false
    end

    option = {}


    GetPlayerCharactersArray = function()
        print('[Multicharacter] Fetching characters from qbx_core...')
        local success, characters, amount = pcall(lib.callback.await, 'qbx_core:server:getCharacters')
        
        if not success then
            print('[Multicharacter] ERROR: Failed to fetch characters:', characters)
            characters = {}
        elseif not characters then
            print('[Multicharacter] No characters found, returning empty slots')
            characters = {}
        else
            print('[Multicharacter] Found', amount or #characters, 'characters')
        end
        
        local maxslots = GetPlayerMaxSlots('src') 
        print('[Multicharacter] Max slots:', maxslots)

        option = {}


        for i = 1, maxslots do
            option[#option + 1] = {
                id = #option + 1,
                firstname = 'First Name',
                lastname = 'Last Name',
                citizenid = 'UNKNOWN',
                emptyslot = true,
                img = '',
                additionalInfo = {
                    job = 'UNEMPLOYED',
                    money = '0',
                    bank = '0',
                    dob = '00/00/0000'
                }
            }
        end



        for _, data in pairs(characters) do
            if data.charinfo.cid <= maxslots then
                option[data.charinfo.cid] = {
                    id = data.charinfo.cid,
                    firstname = data.charinfo.firstname,
                    lastname = data.charinfo.lastname,
                    citizenid = data.citizenid,
                    job = data.job.name,
                    emptyslot = false,
                    img = GetResourceKvpString('slotimg' .. tostring(data.charinfo.cid)),
                    sex = data.charinfo.gender == 0 and true or false,
                    additionalInfo = {
                        job = data.job.label,
                        cash = data.money.cash,
                        bank = data.money.bank,
                        dob = data.charinfo.birthdate
                    }
                }
            end
        end


        return option
    end



    GetAllCharacters = function()
        local characters = lib.callback.await('IV:GetAllCharacters')

        local option = {}

        for _, data in pairs(characters) do
            local number = string.find(data.license, ':')
            local identifier = data.license:sub(number + 1)

            option[#option + 1] = {
                id = data.cid,
                identifier = identifier,
                firstname = data.charinfo.firstname,
                lastname = data.charinfo.lastname,
                sex = data.charinfo.gender == 0 and true or false,
                job = data.job.label,
                cash = data.money.cash,
                bank = data.money.bank,
                dob = data.charinfo.birthdate

            }
        end

        return option
    end

    IsPlayerAdmin = function()
        return lib.callback.await('IV:IsAdmin', false)
    end



    GetPlayerSkin = function(character)
        local model, skin

        model, skin = lib.callback.await('IV:GetSkin', false, character.citizenid)

        if model then
            return model, skin
        elseif character.emptyslot then
            return Config.CreateMenu.model, skin
        else
            return Config.CreateMenu.model, skin
        end
    end

    LoadSkin = function(skin)
        pcall(function() exports['illenium-appearance']:setPedAppearance(PlayerPedId(), json.decode(skin)) end)
    end


    RegisterNetEvent('multicharactere:client:newplayer', function()
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true)
        local resp = NewCharacterAnimation()

        Wait(1000)

        EnableWeatherSync()
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    end)




    SelectCharacter = function(id)
        lib.callback.await('qbx_core:server:loadCharacter', false, id)

        TriggerServerEvent('Update:RoutingBucket', Config.Routingbucket)
        
        -- Get fresh player data
        local playerData = (QBX and QBX.PlayerData) or exports.qbx_core:GetPlayerData()
        local position = playerData and playerData.position or {x = -1042.0, y = -2746.0, z = 21.0, w = 0.0}
        
        if Config.appartmentstart then
            TriggerEvent(Config.appartmentevent, id)
        elseif Config.SpawnSelector then
            TriggerEvent('qb-spawn:client:setupSpawns', id)
            TriggerEvent('qb-spawn:client:openUI', true)
        else
            exports.spawnmanager:spawnPlayer({
                x = position.x,
                y = position.y,
                z = position.z,
                heading = position.w
            })
            
            -- Fix spawning dead issue
            Wait(500)
            local ped = PlayerPedId()
            SetEntityHealth(ped, 200) -- Set full health on spawn
            TriggerEvent('hospital:client:Revive') -- Trigger revive event to clear death state
            
            Wait(500)
            DoScreenFadeIn(1000)
            
            -- Ensure player is unfrozen and can move
            local ped = PlayerPedId()
            FreezeEntityPosition(ped, false)
            SetEntityCollision(ped, true, true)
            
            -- Trigger player loaded events
            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
            TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
            
            -- Wait additional time before fading in to ensure everything loads
            Wait(1000)
            DoScreenFadeIn(1000)
            
            -- Wait for fade in to complete before allowing car spawn
            Wait(1500)
            
            -- Now trigger location and weather sync
            LastLocation()
            EnableWeatherSync()
            
            print('^2[Multicharacter]^7 Player spawned and ready - car spawning now allowed')
        end
    end


    Createcharacter = function(payload)
        DoScreenFadeOut(500)
        Wait(500)

        ClearFocus()
        DeleteCreateCamScene()

        local newData = lib.callback.await('qbx_core:server:createCharacter', false, {
            firstname = payload.firstName,
            lastname = payload.lastName,
            nationality = payload.nationality,
            birthdate = payload.DOB,
            gender = payload.gender == 'Male' and 0 or 1,
            cid = payload.slot,
        })

        if Config.appartmentstart and Config.SpawnSelector then
            TriggerEvent(Config.appartmentevent, newData)
        else
            FreezeEntityPosition(PlayerPedId(), false)
            SetEntityVisible(PlayerPedId(), true)
            local resp = NewCharacterAnimation()

            Wait(1000)

            EnableWeatherSync()
            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
            TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            TriggerServerEvent('Update:RoutingBucket', Config.Routingbucket)
        end
    end
end
