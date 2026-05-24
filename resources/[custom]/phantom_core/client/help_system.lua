-- Phantom Core - Help System
-- Shows players how to use all Phantom features

local helpCategories = {
    {
        name = '🏢 Garages',
        commands = {
            { cmd = '/buygarage', desc = 'Purchase a new garage (2/6/10 car options)' },
            { cmd = 'Walk to garage marker', desc = 'Press E to enter your garage' },
            { cmd = 'Inside garage', desc = 'Click vehicle → DRIVE to take it out' },
            { cmd = 'In vehicle near garage', desc = 'Store vehicle in garage' },
        }
    },
    {
        name = '🔫 Weapons',
        commands = {
            { cmd = 'Hold TAB', desc = 'Open GTA Online style weapon wheel' },
            { cmd = 'Keys 1-6', desc = 'Quick switch weapon categories' },
            { cmd = '/ammunation', desc = 'Open weapon store anywhere' },
            { cmd = 'Walk to Ammu-Nation', desc = 'Red gun blips on map - press E to enter' },
            { cmd = 'Walk to Weapon Locker', desc = 'Blue safe blips - press E to store/retrieve' },
            { cmd = '/weaponlicense', desc = 'Buy weapon license at City Hall' },
        }
    },
    {
        name = '💰 Heists',
        commands = {
            { cmd = 'Bank/Jewelry blips', desc = 'Walk to heist locations (marked on map)' },
            { cmd = '/cancelheist', desc = 'Cancel current heist' },
            { cmd = '/heistreset', desc = 'Admin: Reset all heist cooldowns' },
        }
    },
    {
        name = '🏴‍☠️ Gangs',
        commands = {
            { cmd = '/gangmenu', desc = 'F7 key - Open gang menu (or create one)' },
            { cmd = 'Territory zones', desc = 'Red zones on map - stand in zone and press E to capture' },
            { cmd = 'Start War', desc = 'From gang menu, declare war on rival gang' },
        }
    },
    {
        name = '⚔️ Cops vs Robbers',
        commands = {
            { cmd = '/cvr', desc = 'F5 key - Open PvP arena menu' },
            { cmd = 'Walk to arena', desc = 'Skull blips on map - press F5 to join' },
            { cmd = '/leavequeue', desc = 'Leave match queue' },
        }
    },
    {
        name = '🎉 Events',
        commands = {
            { cmd = '/events', desc = 'See active events and buy lottery tickets' },
            { cmd = '/adminevents', desc = 'Admin: Open event control panel' },
            { cmd = '/moneyrain [amount]', desc = 'Admin: Start money drop event' },
            { cmd = '/freecars', desc = 'Admin: Start free car giveaway' },
            { cmd = '/lottery', desc = 'Buy lottery ticket when active' },
        }
    },
    {
        name = '🔧 Mechanic',
        commands = {
            { cmd = '/ordercustom', desc = 'Place custom vehicle order' },
            { cmd = '/mechanictablet', desc = 'Mechanic: View and manage orders' },
        }
    },
    {
        name = '👤 General',
        commands = {
            { cmd = '/interact', desc = 'E key - Open interaction menu near players/vehicles' },
            { cmd = '/phantomhelp', desc = 'Show this help menu' },
        }
    },
}

-- Open help menu
function OpenHelpMenu()
    local options = {}

    for _, category in ipairs(helpCategories) do
        table.insert(options, {
            title = category.name,
            description = category.commands[1].desc,
            onSelect = function()
                OpenCategoryHelp(category)
            end
        })
    end

    lib.registerContext({
        id = 'phantom_help',
        title = '🎮 Phantom World - Help',
        options = options
    })
    lib.showContext('phantom_help')
end

-- Open category help
function OpenCategoryHelp(category)
    local options = {}

    for _, cmd in ipairs(category.commands) do
        table.insert(options, {
            title = cmd.cmd,
            description = cmd.desc,
            disabled = true,
        })
    end

    -- Back button
    table.insert(options, {
        title = '← Back',
        onSelect = function()
            OpenHelpMenu()
        end
    })

    lib.registerContext({
        id = 'phantom_help_category',
        title = category.name .. ' - Help',
        options = options
    })
    lib.showContext('phantom_help_category')
end

-- Register command
RegisterCommand('phantomhelp', function()
    OpenHelpMenu()
end)

-- Also register as /help (if not taken)
RegisterCommand('phelp', function()
    OpenHelpMenu()
end)

-- Show help on first spawn
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(10000) -- Wait 10 seconds after spawn
    lib.notify({
        title = '🎮 Welcome to Phantom World!',
        description = 'Type /phantomhelp to see all features',
        type = 'info',
        duration = 8000,
    })
end)

print('^2[Phantom Core]^7 Help system loaded')
