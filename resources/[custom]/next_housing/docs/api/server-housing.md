# Server API - Housing

## Exports

### `exports['next_housing']:GetApiVersion()`
Returns the API version (`string`).

### `exports['next_housing']:IsApiReady()`
Returns `true/false` depending on DB initialization state.

### `exports['next_housing']:GetHouseById(houseId[, options])`
Return:

```lua
house, err
```

- `err`: `invalid_house_id`, `house_not_found`.
- `options.decodeJson` (`true` by default): decodes `houseCoords`, `garageCoords`, `images`.

### `exports['next_housing']:GetHouses([filters[, options]])`
Supported filters:
- `ownerIdentifier`
- `isBuyable`
- `belongsToAgency`

### `exports['next_housing']:GetPlayerHouses(identifier[, options])`
Return:

```lua
houses, err
```

Options:
- `includeKeyAccess` (`true` by default): includes houses where player has a key.
- `decodeJson` (`true` by default).

### `exports['next_housing']:PlayerHasAccessToHouse(identifier, houseId)`
Return:

```lua
hasAccess, err
```

### `exports['next_housing']:GetHouseKeys(houseId)`
Return:

```lua
keys, err
```

## House Structure

```lua
{
  id = 12,
  builderIdentifier = "license:...",
  builderName = "Builder Name",
  ownerIdentifier = "license:...",
  ownerName = "Owner Name",
  interior = 3,
  isLocked = true,
  isBuyable = false,
  price = 250000,
  belongsToAgency = false,
  name = "Vinewood House",
  houseCoords = { x = 0.0, y = 0.0, z = 0.0 },
  garageCoords = { x = 0.0, y = 0.0, z = 0.0 },
  images = {},
  raw = {
    house_coords = "...",
    garage_coords = "...",
    images = "..."
  }
}
```

## Example

```lua
local house, err = exports["next_housing"]:GetHouseById(42)
if not house then
    print(("next_housing error: %s"):format(tostring(err)))
    return
end

print(("House %s owner=%s"):format(house.id, tostring(house.ownerIdentifier)))
```
