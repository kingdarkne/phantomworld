# Custom Healing Items for OxoAdmin

## Items Created
- **bandage2**: Heals 12.5% health and removes bleeding/injuries (No job restrictions)
- **medkit2**: Heals 25% health and removes all injuries/bleeding (No job restrictions)
- **illegalbandage**: Heals 15% health and removes bleeding (Illegal jobs only)
- **illegalmedkit**: Heals 30% health and removes all injuries (Illegal jobs only)

## Job Restrictions
**Illegal Jobs** (illegalbandage, illegalmedkit only):
- drugdealer, criminal_doctor, hitman, gunplug, weed_farmer, scammer

Job restrictions are enforced server-side by the admin script for illegal items only, ensuring they work regardless of inventory system. bandage2 and medkit2 have no job restrictions.

## Features
- **Cannot use at 100% health**: Items will not work if you're already at full health
- **Free movement**: You can run and move freely while using items
- **Auto-clear animation**: Animation stops after 3 seconds automatically

## Integration with wasabi_ambulance_v2
These items automatically detect and integrate with wasabi_ambulance_v2 to:
- Remove bleeding status effects
- Clear all injuries
- Restore health percentage-based

## Inventory Setup

### For ox_inventory
Add these items to your `ox_inventory/data/items.lua`:

```lua
["bandage2"] = {
    label = 'Admin Bandage',
    description = 'Heals 12.5% health and removes bleeding',
    weight = 25,
    server = {
        export = "norse_awsome_admins.bandage2"
    }
},
["medkit2"] = {
    label = 'Admin Medkit',
    description = 'Heals 25% health and removes all injuries',
    weight = 250,
    server = {
        export = "norse_awsome_admins.medkit2"
    }
},
["illegalbandage"] = {
    label = 'Bloody Bandage',
    description = 'Heals 15% health and removes bleeding',
    weight = 25,
    server = {
        export = "norse_awsome_admins.illegalbandage"
    }
},
["illegalmedkit"] = {
    label = 'Illegal Medkit',
    description = 'Heals 30% health and removes all injuries',
    weight = 250,
    server = {
        export = "norse_awsome_admins.illegalmedkit"
    }
}
```

### For qb-inventory / qs-inventory / ps-inventory
Add these items to your inventory's `items.lua`:

```lua
['bandage2'] = {
    name = 'bandage2',
    label = 'Admin Bandage',
    weight = 25,
    type = 'item',
    image = 'bandage.png',
    unique = false,
    useable = true,
    shouldClose = true,
    description = 'Heals 25% health and removes bleeding'
},
['medkit2'] = {
    name = 'medkit2',
    label = 'Admin Medkit',
    weight = 250,
    type = 'item',
    image = 'medkit.png',
    unique = false,
    useable = true,
    shouldClose = true,
    description = 'Heals 50% health and removes all injuries'
}
```

For QB-based inventories, also add these to your `qb-core/shared/items.lua` if needed.

## Usage
Players can use these items from their inventory. The items will:
1. Heal the specified percentage (25% or 50%)
2. Clear blood damage visuals
3. Remove bleeding status from wasabi_ambulance_v2
4. Clear injuries (medkit2 also triggers full recovery)

## Notes
- Items work with or without wasabi_ambulance_v2 running
- Compatible with both ESX and QBCore frameworks
- Automatically detects inventory system (ox_inventory, qb-inventory, qs-inventory, ps-inventory)
