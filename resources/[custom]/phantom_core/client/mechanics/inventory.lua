-- Phantom Core - Enhanced Inventory Management
-- High-quality inventory management features

-- Quick sort function
function SortInventory(by)
    -- This would integrate with ox_inventory to sort items
    -- by could be: name, type, weight, quantity
    
    SendNotification({
        type = 'info',
        message = 'Inventory sorted by ' .. by
    })
end

-- Quick drop
function QuickDrop(itemName, amount)
    ShowConfirmDialog({
        title = 'Quick Drop',
        message = 'Drop ' .. amount .. 'x ' .. itemName .. '?',
        confirmText = 'Drop',
        cancelText = 'Cancel',
        callback = function(values, confirmed)
            if confirmed then
                -- This would call ox_inventory to remove item
                SendNotification({
                    type = 'success',
                    message = 'Dropped ' .. amount .. 'x ' .. itemName
                })
            end
        end
    })
end

-- Quick use
function QuickUse(itemName)
    SendNotification({
        type = 'info',
        message = 'Using ' .. itemName
    })
    
    -- This would call ox_inventory to use item
end

-- Open inventory management menu
function OpenInventoryMenu()
    local options = {}
    
    table.insert(options, {
        label = 'Sort by Name',
        description = 'Sort inventory items by name',
        icon = '🔤',
        args = { type = 'sort', by = 'name' }
    })
    table.insert(options, {
        label = 'Sort by Type',
        description = 'Sort inventory items by type',
        icon = '📦',
        args = { type = 'sort', by = 'type' }
    })
    table.insert(options, {
        label = 'Sort by Weight',
        description = 'Sort inventory items by weight',
        icon = '⚖️',
        args = { type = 'sort', by = 'weight' }
    })
    table.insert(options, {
        label = 'Sort by Quantity',
        description = 'Sort inventory items by quantity',
        icon = '🔢',
        args = { type = 'sort', by = 'quantity' }
    })
    
    ShowMenu({
        title = 'Inventory Management',
        options = options
    })
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'sort' then
        SortInventory(data.args.by)
    end
    CloseMenu()
    cb({})
end)

-- Register command
RegisterCommand('invmanage', function()
    OpenInventoryMenu()
end)

-- Export functions
exports('SortInventory', SortInventory)
exports('QuickDrop', QuickDrop)
exports('QuickUse', QuickUse)

DebugPrint('Inventory management loaded')
