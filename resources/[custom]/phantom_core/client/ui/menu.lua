-- Phantom Core - UI Menu System
-- High-quality NUI-based menu system

local activeMenu = nil
local menuCallbacks = {}

-- Show menu
function ShowMenu(options)
    if activeMenu then
        return false, 'Menu already active'
    end
    
    options = options or {}
    local id = options.id or 'phantom_menu_' .. GetGameTimer()
    local title = options.title or 'Menu'
    local position = options.position or 'top-right'
    local menuItems = options.options or {}
    
    -- Generate menu items
    local items = {}
    for index, item in ipairs(menuItems) do
        items[index] = {
            id = item.id or index,
            label = item.label or 'Option',
            description = item.description or '',
            icon = item.icon or '',
            checked = item.checked or false,
            disabled = item.disabled or false,
            values = item.values or nil,
            args = item.args or {}
        }
        
        -- Store callback
        if item.onSelect then
            menuCallbacks[id .. '_' .. items[index].id] = item.onSelect
        end
    end
    
    -- Send to NUI
    SendNUIMessage({
        action = 'showMenu',
        id = id,
        title = title,
        position = position,
        items = items
    })
    
    activeMenu = {
        id = id,
        title = title,
        items = items
    }
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    return true
end

-- Close menu
function CloseMenu()
    if not activeMenu then return end
    
    SendNUIMessage({
        action = 'hideMenu'
    })
    
    SetNuiFocus(false, false)
    
    -- Clear callbacks
    for key, _ in pairs(menuCallbacks) do
        if string.find(key, activeMenu.id) then
            menuCallbacks[key] = nil
        end
    end
    
    activeMenu = nil
end

-- Update menu item
function UpdateMenuItem(menuId, itemId, data)
    if not activeMenu or activeMenu.id ~= menuId then return end
    
    SendNUIMessage({
        action = 'updateMenuItem',
        menuId = menuId,
        itemId = itemId,
        data = data
    })
end

-- NUI Callbacks
RegisterNUICallback('menuItemSelected', function(data, cb)
    local callbackKey = data.menuId .. '_' .. data.itemId
    
    if menuCallbacks[callbackKey] then
        menuCallbacks[callbackKey](data.args)
    end
    
    cb({})
end)

RegisterNUICallback('menuClosed', function(data, cb)
    CloseMenu()
    cb({})
end)

-- Export functions
exports('ShowMenu', ShowMenu)
exports('CloseMenu', CloseMenu)
exports('UpdateMenuItem', UpdateMenuItem)

-- Debug command
if Config.Debug then
    RegisterCommand('testmenu', function()
        ShowMenu({
            title = 'Test Menu',
            options = {
                {
                    label = 'Option 1',
                    description = 'This is option 1',
                    icon = '📝',
                    onSelect = function(args)
                        print('Option 1 selected')
                    end
                },
                {
                    label = 'Option 2',
                    description = 'This is option 2',
                    icon = '⚙️',
                    onSelect = function(args)
                        print('Option 2 selected')
                    end
                },
                {
                    label = 'Close Menu',
                    description = 'Close this menu',
                    icon = '❌',
                    onSelect = function(args)
                        CloseMenu()
                    end
                }
            }
        })
    end)
end

DebugPrint('Menu system loaded')
