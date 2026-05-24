Settings = Settings or {}
FrameWork = {
    Functions = {}
}

local hudInitialized = false

local function getFrameworkPlayerData()
    if not Framework then return nil end

    if Settings.Framework == "ESX" then
        return Framework.GetPlayerData and Framework.GetPlayerData() or nil
    end

    if Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
        return Framework.Functions and Framework.Functions.GetPlayerData and Framework.Functions.GetPlayerData() or nil
    end

    return (Framework.GetPlayerData and Framework.GetPlayerData()) or
        (Framework.Functions and Framework.Functions.GetPlayerData and Framework.Functions.GetPlayerData()) or nil
end

local function hasRequiredPlayerData(PlayerData)
    if not PlayerData then return false end

    if Settings.Framework == "ESX" then
        return PlayerData.job ~= nil
    end

    if Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
        return PlayerData.citizenid ~= nil and PlayerData.job ~= nil and PlayerData.metadata ~= nil and
            PlayerData.money ~= nil
    end

    return true
end

local function getBlackMoneyFromPlayerData(PlayerData)
    if not PlayerData then return 0 end

    if Settings.Framework == "ESX" then
        local accounts = PlayerData.accounts or {}

        for i = 1, #accounts do
            if accounts[i].name == 'black_money' then
                return accounts[i].money or 0
            end
        end

        return 0
    end

    local money = PlayerData.money or {}
    local metadata = PlayerData.metadata or {}

    return money.black_money or money.blackmoney or money.dirty or metadata.black_money or metadata.blackmoney or
        metadata.dirtymoney or 0
end

local function getFormattedLocalDate()
    local now = os.date("*t")
    return string.format("%02d/%02d/%04d", now.day, now.month, now.year)
end

local function waitForFrameworkPlayerData(timeoutMs)
    local timeout = GetGameTimer() + (timeoutMs or 15000)
    local PlayerData = getFrameworkPlayerData()

    while GetGameTimer() < timeout do
        if (Settings.Framework == "QBCore" or Settings.Framework == "Qbox") and not LocalPlayer.state.isLoggedIn then
            Wait(250)
        else
            PlayerData = getFrameworkPlayerData()
            if hasRequiredPlayerData(PlayerData) then
                return PlayerData
            end
            Wait(250)
        end
    end

    return PlayerData
end

local function initializeHud()
    if hudInitialized then return true end
    if Client?.Functions?.SendDataToNUI and Client.Functions.SendDataToNUI() == false then return false end

    Client?.Functions?.UpdateKeyBinds()
    Client?.Functions?.SetMapOnEnter()
    FrameWork?.Functions?.FirstData()
    FrameWork?.Functions?.StartStatusThread()
    FrameWork?.Functions?.StartDataThread()
    Client?.Functions?.UpdatePlayerDataThread()
    FrameWork?.Functions?.PlayerLoaded()

    hudInitialized = true
    return true
end

RegisterNetEvent('esx:onPlayerSpawn', function()
    Wait(1000)
    waitForFrameworkPlayerData(15000)
    initializeHud()
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    waitForFrameworkPlayerData(15000)
    initializeHud()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(1000)
    if not Settings.FrameworkSystems then
        initializeHud()
        return
    end
    if not Framework then return end
    local PlayerData = waitForFrameworkPlayerData(15000)
    if hasRequiredPlayerData(PlayerData) then
        initializeHud()
        FrameWork.Functions.RefreshPlayerData(PlayerData)
    end
end)

FrameWork.Functions.FirstData = function()
    if not Client then return end
    Client.PlayerData.ID = GetPlayerServerId(PlayerId())
end

FrameWork.Functions.PlayerLoaded = function()
    SendNUIMessage({
        action = "playerLoaded"
    })
end

FrameWork.Functions.RefreshPlayerData = function(PlayerData)
    PlayerData = PlayerData or getFrameworkPlayerData()
    if not PlayerData then return false end

    if Settings.Framework == "ESX" then
        local accounts = PlayerData.accounts or {}
        Client.PlayerData.Bank = 0
        Client.PlayerData.Money = 0
        Client.PlayerData.BlackMoney = 0

        for i = 1, #accounts do
            if accounts[i].name == 'bank' then
                Client.PlayerData.Bank = accounts[i].money or 0
            elseif accounts[i].name == 'money' then
                Client.PlayerData.Money = accounts[i].money or 0
            elseif accounts[i].name == 'black_money' then
                Client.PlayerData.BlackMoney = accounts[i].money or 0
            end
        end

        if PlayerData.job then
            local gradeLabel = PlayerData.job.grade_label or ""
            Client.PlayerData.Job = PlayerData.job.label and (PlayerData.job.label .. " ( " .. gradeLabel .. " )") or
                Client.PlayerData.Job
        end

        return true
    end

    if Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
        if PlayerData.money then
            Client.PlayerData.Bank = PlayerData.money.bank or 0
            Client.PlayerData.Money = PlayerData.money.cash or 0
        end

        Client.PlayerData.BlackMoney = getBlackMoneyFromPlayerData(PlayerData)

        if PlayerData.job then
            local gradeName = PlayerData.job.grade and PlayerData.job.grade.name or ""
            Client.PlayerData.Job = PlayerData.job.label and (PlayerData.job.label .. " ( " .. gradeName .. " )") or
                Client.PlayerData.Job
        end

        if PlayerData.metadata then
            if PlayerData.metadata.hunger ~= nil then
                Client.PlayerData.Hunger = math.floor(PlayerData.metadata.hunger)
            end
            if PlayerData.metadata.thirst ~= nil then
                Client.PlayerData.Thrist = math.floor(PlayerData.metadata.thirst)
            end
            if not Settings.DisableStress and Settings.FrameworkSystems and PlayerData.metadata.stress ~= nil then
                Client.PlayerData.Stress = math.floor(PlayerData.metadata.stress)
            end
        end
    end

    return true
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
    if not hudInitialized then return end
    FrameWork.Functions.RefreshPlayerData(PlayerData)
end)

RegisterNetEvent('esx:setJob', function(job)
    if not hudInitialized then return end

    local PlayerData = getFrameworkPlayerData() or {}
    PlayerData.job = job
    FrameWork.Functions.RefreshPlayerData(PlayerData)
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    if not hudInitialized then return end

    local PlayerData = getFrameworkPlayerData() or {}
    local accounts = PlayerData.accounts or {}
    local updated = false

    for i = 1, #accounts do
        if accounts[i].name == account.name then
            accounts[i].money = account.money
            updated = true
            break
        end
    end

    if not updated then
        accounts[#accounts + 1] = account
    end

    PlayerData.accounts = accounts
    FrameWork.Functions.RefreshPlayerData(PlayerData)
end)

FrameWork.Functions.StartDataThread = function()
    local getAccount = function(name)
        local pd = Framework?.GetPlayerData()
        local accounts = pd and pd.accounts
        if not accounts then return end
        for i = 1, #accounts do
            if accounts[i].name == name then
                return accounts[i].money
            end
        end
        return 0
    end

    CreateThread(function()
        while true do
            Wait(2000)
            local PlayerData
            if Settings.FrameworkSystems then
                if Settings.Framework == "ESX" then
                    PlayerData = Framework and Framework.GetPlayerData()
                elseif Framework and Framework.Functions then
                    PlayerData = Framework.Functions.GetPlayerData()
                end
            else
                PlayerData = true
            end
            if PlayerData then
                if not Settings.RealTime then
                    local hours = GetClockHours()
                    local minutes = GetClockMinutes()
                    Client.PlayerData.Time = string.format("%02d : %02d", hours, minutes)
                    Client.PlayerData.Date = getFormattedLocalDate()
                else
                    local timeData = lib.callback.await("tuffHud:server:getTime", false)

                    if type(timeData) == "table" then
                        Client.PlayerData.Time = timeData.time or Client.PlayerData.Time
                        Client.PlayerData.Date = timeData.date or Client.PlayerData.Date
                    else
                        Client.PlayerData.Time = timeData
                        Client.PlayerData.Date = getFormattedLocalDate()
                    end
                end
                if Settings.Framework == "ESX" then
                    Client.PlayerData.Bank = getAccount('bank') or 0
                    Client.PlayerData.Money = getAccount('money') or 0
                    Client.PlayerData.BlackMoney = getAccount('black_money') or 0
                    Client.PlayerData.Job = PlayerData?.job and
                        PlayerData?.job?.label .. " ( " .. PlayerData?.job?.grade_label .. " )"
                elseif Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
                    if PlayerData?.money then
                        Client.PlayerData.Bank = PlayerData?.money['bank'] or 0
                        Client.PlayerData.Money = PlayerData?.money['cash'] or 0
                        Client.PlayerData.BlackMoney = getBlackMoneyFromPlayerData(PlayerData)
                        Client.PlayerData.Job = PlayerData?.job and
                            PlayerData?.job?.label .. " ( " .. PlayerData?.job?.grade?.name .. " )"
                    end
                end
            end
        end
    end)
end

FrameWork.Functions.StartStatusThread = function()
    CreateThread(function()
        while true do
            Wait(1000)
            local health = math.floor(GetEntityHealth(PlayerPedId()) - 100)
            Client.PlayerData.Health = health >= 0 and health or 0
            local armor = GetPedArmour(PlayerPedId())
            Client.PlayerData.Armor = armor
            local oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10)
            Client.PlayerData.Oxygen = oxygen >= 0 and (oxygen > 100 and 100 or oxygen) or 0
            local stamina = math.floor(100 - (GetPlayerSprintStaminaRemaining(PlayerId())))
            Client.PlayerData.Stamina = stamina >= 0 and stamina or 0
            local speaking = NetworkIsPlayerTalking(PlayerId())
            Client.PlayerData.Speaking = speaking
            local proximity = FrameWork.Functions.GetProximityRange()
            Client.PlayerData.Proximity = proximity
        end
    end)

    if Settings.Framework == "ESX" then
        AddEventHandler("esx_status:onTick", function(data)
            for i = 1, #data do
                if data[i].name == "thirst" then
                    Client.PlayerData.Thrist = math.floor(data[i].percent)
                end
                if data[i].name == "hunger" then
                    Client.PlayerData.Hunger = math.floor(data[i].percent)
                end
                if not Settings.DisableStress and Settings.FrameworkSystems and data[i].name == "stress" then
                    Client.PlayerData.Stress = math.floor(data[i].percent)
                end
            end
        end)
    elseif Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
        CreateThread(function()
            while true do
                FrameWork.Functions.RefreshPlayerData()
                Wait(1000)
            end
        end)
    end
end

FrameWork.Functions.GetJob = function()
    if not Settings.FrameworkSystems then return false end
    local PlayerData = Settings.Framework == "ESX" and Framework?.GetPlayerData() or
        Framework?.Functions?.GetPlayerData()
    if PlayerData then
        if Settings.Framework == "ESX" then
            if PlayerData?.job and PlayerData?.job?.name then
                return PlayerData.job.name
            else
                return false
            end
        elseif Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
            if PlayerData?.job and PlayerData?.job?.name then
                return PlayerData.job.name
            else
                return false
            end
        end
    else
        return false
    end
end

FrameWork.Functions.GetStress = function()
    return Client?.PlayerData?.Stress or false
end

FrameWork.Functions.GetNitro = function(vehicle)
    -- add your own system if you have

    return 0
end

FrameWork.Functions.UpdateStress = function()
    if Settings.Framework == "ESX" then
        TriggerEvent('esx_status:add', 'stress', 60000)
    elseif Settings.Framework == "QBCore" or Settings.Framework == "Qbox" then
        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
    end
end

FrameWork.Functions.GetProximityRange = function()
    if not Settings.FrameworkSystems then return 2 end
    if GetResourceState("pma-voice") == "started" then
        local proximity = Player(GetPlayerServerId(PlayerId())).state['proximity']
        local modes = {
            ["Whisper"] = 1,
            ["Normal"] = 2,
            ["Shouting"] = 3
        }
        return modes[proximity?.mode] or 2
    elseif GetResourceState("saltychat") == "started" then
        local proximity = exports["saltychat"]:GetVoiceRange()
        local mode = 2
        if proximity <= 5.0 then
            mode = 1
        elseif proximity >= 10.0 then
            mode = 3
        end
        return mode
    else
        if Settings and Settings.Debug then
            print(
                "[tuff-hud][DEBUG] No voice resource found, configure proximity range manually in client/framework.lua!")
        end
        return 2
    end
end

FrameWork.Functions.Notify = function(title, text, type, duration)
    lib.notify({
        title = title,
        description = text,
        type = type,
        duration = duration
    })
end
