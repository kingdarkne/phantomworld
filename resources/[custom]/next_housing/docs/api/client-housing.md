# Client API - Housing, Keys, Garage

All exports below are public and safe to use from another resource, even with escrow enabled.

## Data Reads

### `exports['next_housing']:RequestHouseList(cb)`
Returns all houses.

```lua
cb(houses)
```

### `exports['next_housing']:RequestHouseById(houseId, cb)`
Returns one house.

```lua
cb(house, errorCode)
```

### `exports['next_housing']:RequestOwnedHouses(cb)`
Returns houses owned by current player.

```lua
cb(houses, errorCode)
```

## House Actions

### `exports['next_housing']:HouseToggleLock(houseId, cb)`
Toggle lock state for an authorized player (owner/key).

```lua
cb(success, reason, locked)
```

### `exports['next_housing']:HouseLock(houseId, cb)`
Force lock if possible.

```lua
cb(success, reason, locked, changed)
```

### `exports['next_housing']:HouseUnlock(houseId, cb)`
Force unlock if possible.

```lua
cb(success, reason, locked, changed)
```

### `exports['next_housing']:HouseBuy(houseId, cb)`
Direct buy flow for current player.

```lua
cb(success, message)
```

### `exports['next_housing']:HouseResetMarket(houseId, cb)`
Admin-only reset to market.

```lua
cb(success, message)
```

### `exports['next_housing']:HouseSetOwner(houseId, ownerRef, cb)`
Admin-only owner change. `ownerRef` can be player server id or identifier string.

```lua
cb(success, message, newOwnerName)
```

### `exports['next_housing']:HouseSetPrice(houseId, price, cb)`
Admin-only price change.

```lua
cb(success, message)
```

## Keys Actions

### `exports['next_housing']:KeysList(houseId, cb)`
List keys for one house (owner/tenant permission rules still apply).

```lua
cb(success, keys, reason)
```

### `exports['next_housing']:KeysGrant(houseId, targetServerId, cb)`
Grant key to online player.

```lua
cb(success, message)
```

### `exports['next_housing']:KeysRevoke(houseId, keyRef, cb)`
Revoke key. `keyRef` can be:
- `identifier` string;
- table with `identifier` and/or `player_name`.

```lua
cb(success, reason)
```

## Garage Actions

### `exports['next_housing']:GarageListByHouseId(houseId, cb)`
Returns owned/stored vehicles for a house garage context.

```lua
cb(success, vehicles, reason)
```

### `exports['next_housing']:GarageOpenByHouseId(houseId, cb)`
Open garage UI by `houseId` only. No manual coords required.

```lua
cb(success, reason)
```

### `exports['next_housing']:GarageStoreByHouseId(houseId, cb)`
Run store flow by `houseId` only.

```lua
cb(success, reason)
```

### `exports['next_housing']:GarageSpawnByHouseId(houseId, selector, cb)`
Spawn one garage vehicle at house garage spawn point.

`selector` can be:
- plate string (recommended);
- number;
- table with `plate`.

If selector is missing or not found, first available vehicle is used.

```lua
cb(success, reason, selectedVehicle)
```

## Example

```lua
RegisterCommand("nh_lock_house_12", function()
    exports["next_housing"]:HouseLock(12, function(success, reason, locked)
        print(("lock success=%s reason=%s locked=%s"):format(
            tostring(success),
            tostring(reason),
            tostring(locked)
        ))
    end)
end)

RegisterCommand("nh_spawn_house_12", function(_, args)
    local plate = args[1]
    exports["next_housing"]:GarageSpawnByHouseId(12, plate, function(success, reason)
        print(("spawn success=%s reason=%s"):format(tostring(success), tostring(reason)))
    end)
end)
```
