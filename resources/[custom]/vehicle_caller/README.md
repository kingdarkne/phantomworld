# Vehicle Calling Menu

A modern, easy-to-use vehicle calling menu for FiveM that allows players to spawn their owned and rented vehicles. Integrated with qbx_core and ox_inventory.

## Features

- **Modern UI**: Clean, dark-themed interface with smooth animations
- **Three Categories**: Personal Vehicles, Rented Vehicles, Job Vehicles
- **Easy Access**: Press F3 (configurable) or use `/vehicles` command
- **qbx_core Integration**: Works with qbx_garages for owned vehicles
- **ox_inventory Compatible**: Designed for ox_inventory setups
- **Key System**: Integrates with qbx_vehiclekeys for key management
- **Smart Spawning**: Finds clear spawn positions automatically

## Installation

1. Place the `vehicle_caller` folder in your `resources/[custom]/` directory
2. Add `ensure vehicle_caller` to your `server.cfg`
3. Restart your server

## Configuration

Edit `config.lua` to customize:

```lua
-- Menu settings
Config.Menu = {
    enabled = true,
    openKey = 'F3', -- Key to open the menu
    command = 'vehicles', -- Command to open the menu
}

-- Vehicle categories
Config.Categories = { ... }

-- Spawn settings
Config.Spawn = {
    distance = 30, -- Max distance to spawn vehicle
    spawnInVehicle = true, -- Spawn player inside vehicle
    clearArea = true, -- Clear area before spawning
    despawnPrevious = false, -- Despawn previous vehicle
}
```

## Usage

- **Open Menu**: Press `F3` (default) or type `/vehicles`
- **Select Category**: Click on Personal, Rented, or Job tab
- **Spawn Vehicle**: Click on a vehicle to spawn it
- **Close**: Press `ESC` or click the X button

## Commands

- `/vehicles` - Open the vehicle menu

## Exports

```lua
-- Open the vehicle menu
exports['vehicle_caller']:OpenVehicleMenu()

-- Close the vehicle menu
exports['vehicle_caller']:CloseVehicleMenu()
```

## Integration

The menu integrates with:
- **qbx_garages**: Fetches owned vehicles from garages
- **qbx_vehiclekeys**: Automatically gives keys on spawn
- **Player Metadata**: Falls back to player metadata if garages unavailable

## Customization

### Adding Custom Job Vehicles

Edit `client/main.lua` in the `GetJobVehicles()` function:

```lua
elseif job == 'yourjob' then
    table.insert(jobVehicles, { model = 'vehicle_model', name = 'Vehicle Name', type = 'job' })
end
```

### Changing the UI Theme

Edit `html/style.css` to customize colors and styling:
- Change the gradient in `.menu-container` for background
- Modify `.menu-header h2` for header colors
- Adjust `.spawn-btn` gradient for button colors

## Troubleshooting

**Menu not opening:**
- Check that qbx_core is running
- Verify the keybind isn't conflicting with other resources
- Check console for errors

**Vehicles not showing:**
- Ensure qbx_garages is properly configured
- Check that vehicles are in the player's metadata
- Verify vehicle names match the config

**Vehicle fails to spawn:**
- Check if the area is clear of obstacles
- Verify vehicle model exists in the game
- Check console for spawn errors

## Dependencies

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_lib](https://github.com/overextended/ox_lib)

Optional:
- [qbx_garages](https://github.com/Qbox-project/qbx_garages)
- [qbx_vehiclekeys](https://github.com/Qbox-project/qbx_vehiclekeys)

## Credits

- UI inspired by modern FiveM menus
- Integration with qbx_core framework
- ox_inventory compatibility

## License

MIT License
