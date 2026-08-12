-- Phantom Core - Banking System
-- High-quality banking with ATMs and transactions

local atmBlips = {}

-- Create ATM blips
function CreateATMBlips()
    for _, atm in ipairs(Config.Economy.Banking.ATMLocations) do
        local blip = CreateBlip(atm.coords, 277, 2, 0.6, 'ATM')
        table.insert(atmBlips, blip)
    end
end

-- Remove ATM blips
function RemoveATMBlips()
    for _, blip in ipairs(atmBlips) do
        RemoveBlip(blip)
    end
    atmBlips = {}
end

-- Open banking menu
function OpenBankingMenu()
    local playerData = GetPlayerData()
    if not playerData or not playerData.money then
        SendNotification({
            notificationType = 'error',
            message = 'Unable to load account data'
        })
        return
    end
    
    local cash = playerData.money.cash or 0
    local bank = playerData.money.bank or 0
    
    local options = {}
    
    -- Account info
    table.insert(options, {
        label = 'Cash: ' .. FormatMoney(cash),
        description = 'Money in your pocket',
        icon = '💵',
        disabled = true
    })
    table.insert(options, {
        label = 'Bank: ' .. FormatMoney(bank),
        description = 'Money in your bank account',
        icon = '🏦',
        disabled = true
    })
    
    -- Actions
    table.insert(options, {
        label = 'Deposit',
        description = 'Deposit cash to bank',
        icon = '⬇️',
        args = { type = 'deposit' }
    })
    table.insert(options, {
        label = 'Withdraw',
        description = 'Withdraw cash from bank',
        icon = '⬆️',
        args = { type = 'withdraw' }
    })
    table.insert(options, {
        label = 'Transfer',
        description = 'Transfer money to another player',
        icon = '📤',
        args = { type = 'transfer' }
    })
    table.insert(options, {
        label = 'Transaction History',
        description = 'View recent transactions',
        icon = '📜',
        args = { type = 'history' }
    })
    
    ShowMenu({
        title = 'Banking',
        options = options
    })
end

-- Deposit money
function DepositMoney()
    ShowInputDialog({
        title = 'Deposit Money',
        inputs = {
            {
                type = 'number',
                label = 'Amount',
                placeholder = 'Enter amount to deposit',
                required = true
            }
        },
        callback = function(values, submitted)
            if submitted and values[1] then
                local amount = tonumber(values[1])
                local playerData = GetPlayerData()
                local cash = playerData.money.cash or 0
                
                if amount > cash then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Insufficient cash'
                    })
                    return
                end
                
                if amount <= 0 then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Invalid amount'
                    })
                    return
                end
                
                -- Trigger server to process deposit
                TriggerServerEvent('phantom:server:depositMoney', amount)
            end
        end
    })
end

-- Withdraw money
function WithdrawMoney()
    ShowInputDialog({
        title = 'Withdraw Money',
        inputs = {
            {
                type = 'number',
                label = 'Amount',
                placeholder = 'Enter amount to withdraw',
                required = true
            }
        },
        callback = function(values, submitted)
            if submitted and values[1] then
                local amount = tonumber(values[1])
                local playerData = GetPlayerData()
                local bank = playerData.money.bank or 0
                
                if amount > bank then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Insufficient bank balance'
                    })
                    return
                end
                
                if amount <= 0 then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Invalid amount'
                    })
                    return
                end
                
                TriggerServerEvent('phantom:server:withdrawMoney', amount)
            end
        end
    })
end

-- Transfer money
function TransferMoney()
    ShowInputDialog({
        title = 'Transfer Money',
        inputs = {
            {
                type = 'number',
                label = 'Player ID',
                placeholder = 'Enter player ID',
                required = true
            },
            {
                type = 'number',
                label = 'Amount',
                placeholder = 'Enter amount to transfer',
                required = true
            }
        },
        callback = function(values, submitted)
            if submitted and values[1] and values[2] then
                local playerId = tonumber(values[1])
                local amount = tonumber(values[2])
                local playerData = GetPlayerData()
                local bank = playerData.money.bank or 0
                
                if amount > bank then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Insufficient bank balance'
                    })
                    return
                end
                
                if amount <= 0 then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Invalid amount'
                    })
                    return
                end
                
                TriggerServerEvent('phantom:server:transferMoney', playerId, amount)
            end
        end
    })
end

-- View transaction history
function ViewTransactionHistory()
    TriggerServerEvent('phantom:server:getTransactionHistory')
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'deposit' then
        DepositMoney()
    elseif data.args.type == 'withdraw' then
        WithdrawMoney()
    elseif data.args.type == 'transfer' then
        TransferMoney()
    elseif data.args.type == 'history' then
        ViewTransactionHistory()
    end
    CloseMenu()
    cb({})
end)

-- ATM interaction thread
CreateThread(function()
    CreateATMBlips()
    
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for _, atm in ipairs(Config.Economy.Banking.ATMLocations) do
            local distance = #(coords - atm.coords)
            
            if distance < 3.0 then
                DrawMarker(36, atm.coords, vec3(0.3, 0.3, 0.3), {r = 0, g = 150, b = 255, a = 100})
                
                if distance < 1.5 then
                    Draw3DText(atm.coords, '[E] ATM', 0.5, 4)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        OpenBankingMenu()
                    end
                end
            end
        end
        
        Wait(0)
    end
end)

-- Register command
RegisterCommand('bank', function()
    OpenBankingMenu()
end)

-- Server events
RegisterNetEvent('phantom:client:bankingUpdate', function(newCash, newBank)
    SendNotification({
        notificationType = 'success',
        message = 'Transaction completed'
    })
end)

RegisterNetEvent('phantom:client:transactionHistory', function(transactions)
    -- Display transaction history
    local options = {}
    
    for _, transaction in ipairs(transactions) do
        local icon = transaction.type == 'deposit' and '⬇️' or transaction.type == 'withdraw' and '⬆️' or '📤'
        table.insert(options, {
            label = transaction.type:upper(),
            description = FormatMoney(transaction.amount) .. ' - ' .. transaction.description,
            icon = icon,
            disabled = true
        })
    end
    
    table.insert(options, {
        label = '← Back',
        description = 'Return to banking menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Transaction History',
        options = options
    })
end)

-- Export functions
exports('OpenBankingMenu', OpenBankingMenu)

DebugPrint('Banking system loaded')
