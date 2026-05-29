-- Phantom Core - Vehicle Spawner
-- High-quality vehicle spawner with categories and filtering

local vehicleCategories = {
    { id = 'sports', name = 'Sports', icon = '🏎️' },
    { id = 'super', name = 'Super', icon = '⚡' },
    { id = 'sedans', name = 'Sedans', icon = '🚗' },
    { id = 'suvs', name = 'SUVs', icon = '🚙' },
    { id = 'muscle', name = 'Muscle', icon = '💪' },
    { id = 'compacts', name = 'Compacts', icon = '🚘' },
    { id = 'coupes', name = 'Coupes', icon = '🚖' },
    { id = 'motorcycles', name = 'Motorcycles', icon = '🏍️' },
    { id = 'offroad', name = 'Off-Road', icon = '🚜' },
    { id = 'emergency', name = 'Emergency', icon = '🚑' },
}

local vehicles = {
    sports = {
        { model = 'kuruma', name = 'Kuruma', price = 50000 },
        { model = 'sultan', name = 'Sultan', price = 35000 },
        { model = 'elegy', name = 'Elegy RH8', price = 55000 },
        { model = 'futo', name = 'Futo', price = 15000 },
    },
    super = {
        { model = 'adder', name = 'Adder', price = 1000000 },
        { model = 't20', name = 'T20', price = 2000000 },
        { model = 'zentorno', name = 'Zentorno', price = 1500000 },
        { model = 'entityxf', name = 'Entity XF', price = 795000 },
    },
    sedans = {
        { model = 'primo', name = 'Primo', price = 8000 },
        { model = 'asterope', name = 'Astin', price = 12000 },
        { model = 'ingot', name = 'Ingot', price = 10000 },
        { model = 'surano', name = 'Surano', price = 110000 },
    },
    suvs = {
        { model = 'baller', name = 'Baller', price = 90000 },
        { model = 'cavalcade', name = 'Cavalcade', price = 60000 },
        { model = 'granger', name = 'Granger', price = 35000 },
        { model = 'patriot', name = 'Patriot', price = 75000 },
    },
    muscle = {
        { model = 'dominator', name = 'Dominator', price = 35000 },
        { model = 'dukes', name = 'Dukes', price = 25000 },
        { model = 'gauntlet', name = 'Gauntlet', price = 30000 },
        { model = 'blade', name = 'Blade', price = 15000 },
    },
    compacts = {
        { model = 'blista', name = 'Blista', price = 5000 },
        { model = 'dilettante', name = 'Dilettante', price = 7000 },
        { model = 'issi2', name = 'Issi', price = 9000 },
        { model = 'panto', name = 'Panto', price = 4000 },
    },
    coupes = {
        { model = 'coupe', name = 'Cognoscenti Coupe', price = 180000 },
        { model = 'exemplar', name = 'Exemplar', price = 200000 },
        { model = 'f620', name = 'F620', price = 80000 },
        { model = 'oracle', name = 'Oracle', price = 80000 },
    },
    motorcycles = {
        { model = 'akuma', name = 'Akuma', price = 9000 },
        { model = 'bati', name = 'Bati 801', price = 15000 },
        { model = 'double', name = 'Double T', price = 12000 },
        { model = 'carbonrs', name = 'Carbon RS', price = 40000 },
    },
    offroad = {
        { model = 'brawler', name = 'Brawler', price = 45000 },
        { model = 'dune', name = 'Dune Buggy', price = 20000 },
        { model = 'rebel', name = 'Rebel', price = 25000 },
        { model = 'sandking', name = 'Sandking', price = 38000 },
    },
    emergency = {
        { model = 'ambulance', name = 'Ambulance', price = 5000 },
        { model = 'firetruk', name = 'Fire Truck', price = 5000 },
        { model = 'police', name = 'Police Cruiser', price = 5000 },
        { model = 'police2', name = 'Police Interceptor', price = 5000 },
    },
}

local currentCategory = 'sports'
local currentFilter = ''

-- Open vehicle spawner menu
function OpenVehicleSpawner()
    local options = {}
    
    -- Add category selector
    for _, category in ipairs(vehicleCategories) do
        table.insert(options, {
            label = category.name,
            description = 'Browse ' .. category.name .. ' vehicles',
            icon = category.icon,
            args = { type = 'category', id = category.id }
        })
    end
    
    ShowMenu({
        title = 'Vehicle Categories',
        options = options
    })
end

-- Open category menu
function OpenCategory(categoryId)
    currentCategory = categoryId
    local categoryVehicles = vehicles[categoryId] or {}
    local options = {}
    
    -- Filter vehicles
    for _, vehicle in ipairs(categoryVehicles) do
        if currentFilter == '' or string.find(string.lower(vehicle.name), string.lower(currentFilter)) then
            table.insert(options, {
                label = vehicle.name,
                description = FormatMoney(vehicle.price),
                icon = '🚗',
                args = { type = 'spawn', model = vehicle.model, price = vehicle.price }
            })
        end
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back to Categories',
        description = 'Return to category selection',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = vehicleCategories[categoryId].name .. ' Vehicles',
        options = options
    })
end

-- Spawn vehicle
function SpawnVehicleFromMenu(model, price)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Show progress
    ShowProgressBar({
        duration = 2000,
        label = 'Spawning vehicle...',
        canCancel = false
    })
    
    -- Spawn vehicle
    local vehicle, error = SpawnVehicle(model, coords, heading)
    
    if vehicle then
        -- Set player as driver
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        
        SendNotification({
            notificationType = 'vehicle',
            message = 'Vehicle spawned: ' .. model
        })
        
        -- Deduct money (if using economy system)
        -- This would integrate with the banking system
        
        return true
    else
        SendNotification({
            notificationType = 'error',
            message = 'Failed to spawn vehicle: ' .. (error or 'Unknown error')
        })
        return false
    end
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'category' then
        OpenCategory(data.args.id)
    elseif data.args.type == 'spawn' then
        SpawnVehicleFromMenu(data.args.model, data.args.price)
        CloseMenu()
    elseif data.args.type == 'back' then
        OpenVehicleSpawner()
    end
    cb({})
end)

-- Command to open spawner
RegisterCommand('vspawner', function()
    OpenVehicleSpawner()
end)

-- Export functions
exports('OpenVehicleSpawner', OpenVehicleSpawner)
exports('SpawnVehicle', SpawnVehicleFromMenu)

DebugPrint('Vehicle spawner loaded')
