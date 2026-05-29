-- Phantom Core - Housing System
-- High-quality housing system with purchase and customization

local properties = {
    { id = 'apt_vinewood', name = 'Vinewood Apartment', type = 'Apartment', price = 100000, coords = vec3(295.8, -208.2, 54.5) },
    { id = 'house_richman', name = 'Richman House', type = 'House', price = 500000, coords = vec3(-886.5, 44.3, 49.2) },
    { id = 'mansion_vinewood', name = 'Vinewood Mansion', type = 'Mansion', price = 2000000, coords = vec3(-858.4, 689.4, 152.9) },
}

local playerProperties = {}

-- Open housing menu
function OpenHousingMenu()
    local options = {}
    
    -- Browse properties
    table.insert(options, {
        label = 'Browse Properties',
        description = 'View available properties',
        icon = '🏠',
        args = { type = 'browse' }
    })
    
    -- My properties
    table.insert(options, {
        label = 'My Properties',
        description = 'View your owned properties',
        icon = '🔑',
        args = { type = 'myprops' }
    })
    
    ShowMenu({
        title = 'Housing',
        options = options
    })
end

-- Browse properties
function BrowseProperties()
    local options = {}
    
    for _, property in ipairs(properties) do
        local playerData = GetPlayerData()
        local owned = false
        
        -- Check if owned
        for _, prop in ipairs(playerProperties) do
            if prop.id == property.id then
                owned = true
                break
            end
        end
        
        table.insert(options, {
            label = property.name,
            description = FormatMoney(property.price) .. (owned and ' [OWNED]' or ''),
            icon = owned and '🔑' or '🏠',
            disabled = owned,
            args = { type = 'view', property = property }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to housing menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Available Properties',
        options = options
    })
end

-- View property details
function ViewProperty(property)
    local options = {}
    
    table.insert(options, {
        label = property.name,
        description = property.type .. ' - ' .. FormatMoney(property.price),
        icon = '🏠',
        disabled = true
    })
    
    table.insert(options, {
        label = 'Purchase Property',
        description = 'Buy this property for ' .. FormatMoney(property.price),
        icon = '💰',
        args = { type = 'purchase', property = property }
    })
    
    table.insert(options, {
        label = '← Back',
        description = 'Return to property list',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Property Details',
        options = options
    })
end

-- Purchase property
function PurchaseProperty(property)
    local playerData = GetPlayerData()
    local bank = playerData.money.bank or 0
    
    if bank < property.price then
        SendNotification({
            notificationType = 'error',
            message = 'Insufficient funds'
        })
        return
    end
    
    ShowConfirmDialog({
        title = 'Purchase Property',
        message = 'Purchase ' .. property.name .. ' for ' .. FormatMoney(property.price) .. '?',
        confirmText = 'Purchase',
        cancelText = 'Cancel',
        callback = function(values, confirmed)
            if confirmed then
                TriggerServerEvent('phantom:server:purchaseProperty', property.id, property.price)
            end
        end
    })
end

-- My properties
function MyProperties()
    local options = {}
    
    if #playerProperties == 0 then
        table.insert(options, {
            label = 'No properties owned',
            description = 'Purchase a property to get started',
            icon = '🏠',
            disabled = true
        })
    else
        for _, prop in ipairs(playerProperties) do
            table.insert(options, {
                label = prop.name,
                description = prop.type,
                icon = '🏠',
                args = { type = 'enter', property = prop }
            })
        end
    end
    
    table.insert(options, {
        label = '← Back',
        description = 'Return to housing menu',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'My Properties',
        options = options
    })
end

-- Enter property
function EnterProperty(property)
    -- Teleport to property interior
    SetEntityCoords(PlayerPedId(), property.coords)
    
    SendNotification({
        notificationType = 'success',
        message = 'Entered ' .. property.name
    })
    
    CloseMenu()
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'browse' then
        BrowseProperties()
    elseif data.args.type == 'myprops' then
        MyProperties()
    elseif data.args.type == 'view' then
        ViewProperty(data.args.property)
    elseif data.args.type == 'purchase' then
        PurchaseProperty(data.args.property)
    elseif data.args.type == 'enter' then
        EnterProperty(data.args.property)
    elseif data.args.type == 'back' then
        OpenHousingMenu()
    end
    cb({})
end)

-- Server events
RegisterNetEvent('phantom:client:propertyPurchased', function(propertyId)
    SendNotification({
        notificationType = 'success',
        message = 'Property purchased!'
    })
    
    -- Refresh properties
    TriggerServerEvent('phantom:server:getPlayerProperties')
end)

RegisterNetEvent('phantom:client:syncProperties', function(props)
    playerProperties = props
end)

-- Register command
RegisterCommand('housing', function()
    OpenHousingMenu()
end)

-- Export functions
exports('OpenHousingMenu', OpenHousingMenu)

DebugPrint('Housing system loaded')
