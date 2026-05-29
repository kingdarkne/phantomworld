-- Phantom Core - Tax System (Client)
-- Client-side tax system UI

-- Open tax menu
function OpenTaxMenu()
    local options = {}
    
    table.insert(options, {
        label = 'Income Tax',
        description = 'View income tax information',
        icon = '💰',
        args = { type = 'income' }
    })
    table.insert(options, {
        label = 'Property Tax',
        description = 'View property tax information',
        icon = '🏠',
        args = { type = 'property' }
    })
    table.insert(options, {
        label = 'Sales Tax',
        description = 'View sales tax information',
        icon = '🛒',
        args = { type = 'sales' }
    })
    table.insert(options, {
        label = 'Tax History',
        description = 'View tax payment history',
        icon = '📜',
        args = { type = 'history' }
    })
    
    ShowMenu({
        title = 'Tax System',
        options = options
    })
end

-- Show tax info
function ShowTaxInfo(taxType)
    local info = ''
    local rate = 0
    
    if taxType == 'income' then
        rate = Config.Economy.Tax.IncomeTaxRate
        info = 'Income tax is ' .. (rate * 100) .. '% of your earnings'
    elseif taxType == 'property' then
        rate = Config.Economy.Tax.PropertyTaxRate
        info = 'Property tax is ' .. (rate * 100) .. '% of property value'
    elseif taxType == 'sales' then
        rate = Config.Economy.Shops.TaxRate
        info = 'Sales tax is ' .. (rate * 100) .. '% on all purchases'
    end
    
    SendNotification({
        notificationType = 'info',
        message = info
    })
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'income' or data.args.type == 'property' or data.args.type == 'sales' then
        ShowTaxInfo(data.args.type)
    elseif data.args.type == 'history' then
        TriggerServerEvent('phantom:server:getTaxHistory')
    end
    CloseMenu()
    cb({})
end)

-- Register command
RegisterCommand('tax', function()
    OpenTaxMenu()
end)

-- Server event
RegisterNetEvent('phantom:client:taxHistory', function(taxes)
    local options = {}
    
    for _, tax in ipairs(taxes) do
        table.insert(options, {
            label = tax.type:upper(),
            description = FormatMoney(tax.amount) .. ' - ' .. tax.description,
            icon = '💰',
            disabled = true
        })
    end
    
    table.insert(options, {
        label = '← Back',
        description = 'Return to tax menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Tax History',
        options = options
    })
end)

-- Export functions
exports('OpenTaxMenu', OpenTaxMenu)

DebugPrint('Tax system loaded')
