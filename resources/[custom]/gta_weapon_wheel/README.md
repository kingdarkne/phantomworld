# GTA-Online Style Weapon Wheel

A standalone GTA-Online style weapon wheel resource for FiveM that integrates with ox_inventory and qbx_core. This resource runs alongside your existing custom weapon systems without replacing them.

## Features

- **GTA-Online Style UI**: Circular weapon wheel with smooth animations
- **ox_inventory Integration**: Automatically fetches weapons from ox_inventory
- **qbx_core Support**: Compatible with qbx_core framework
- **Standalone**: Works alongside your existing phantom_weapons system
- **Configurable**: Easy to customize categories, colors, and controls
- **Weapon Categories**: Handguns, SMGs, Shotguns, Assault Rifles, LMGs, Snipers, Heavy Weapons, Thrown

## Installation

1. Place the `gta_weapon_wheel` folder in your `resources/[custom]/` directory
2. Add `ensure gta_weapon_wheel` to your `server.cfg`
3. Restart your server

## Configuration

Edit `config.lua` to customize:

```lua
-- Enable/disable the weapon wheel
Config.Enabled = true

-- Control to open the weapon wheel (default: TAB)
Config.OpenKey = 37 -- TAB key

-- Weapon categories
Config.Categories = { ... }

-- Integration settings
Config.Integration = {
    useOxInventory = true,  -- Enable ox_inventory integration
    useQBXCore = true,      -- Enable qbx_core integration
    syncWithInventory = true,
    autoEquip = true,
}
```

## Usage

- **Open Weapon Wheel**: Press `TAB` (default)
- **Select Category**: Click on a category icon
- **Select Weapon**: Click on a weapon from the list
- **Close**: Press `ESC` or click outside the wheel

## Commands

- `/weaponwheel` - Toggle the weapon wheel

## Exports

```lua
-- Open the weapon wheel
exports['gta_weapon_wheel']:OpenWeaponWheel()

-- Close the weapon wheel
exports['gta_weapon_wheel']:CloseWeaponWheel()

-- Toggle the weapon wheel
exports['gta_weapon_wheel']:ToggleWeaponWheel()
```

## Integration with Existing Systems

This resource is designed to work alongside your existing `phantom_weapons` system. You can:

1. **Use Both Systems**: Keep both enabled and use whichever you prefer
2. **Toggle Between Them**: Use the exports to enable/disable each system
3. **Custom Controls**: Change the keybind in config.lua to avoid conflicts

Example of switching between systems:

```lua
-- In your custom script
-- Disable phantom_weapons weapon wheel
Config.WeaponWheel.enabled = false

-- Enable gta_weapon_wheel
exports['gta_weapon_wheel']:OpenWeaponWheel()
```

## Dependencies

- [ox_inventory](https://github.com/overextended/ox_inventory)
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)

## Troubleshooting

**Weapon wheel not opening:**
- Check that ox_inventory is running
- Verify the keybind isn't conflicting with other resources
- Check console for errors

**Weapons not showing:**
- Ensure ox_inventory is properly configured
- Check that weapons are in the inventory
- Verify weapon names match the config

**Conflicts with phantom_weapons:**
- Change the keybind in config.lua
- Disable one system's weapon wheel via config
- Use exports to control which system is active

## Credits

- Inspired by GTA V's weapon wheel
- Integration with ox_inventory by OverExtended
- qbx_core framework by Qbox Project

## License

MIT License

## Support

For issues or suggestions, please create an issue in the repository.
