# Server API - Settings and Markers

## Exports

### `exports['next_housing']:GetSetting(key[, defaultValue])`
Returns one global setting (`next_housing_settings`) or `defaultValue`.

### `exports['next_housing']:GetSettings(keys)`
Returns a table `key -> value`.

If `keys` is `nil` or empty, the full public settings cache is returned.

Security note:
- Only whitelisted public keys are readable from this API.
- Private or premium keys (including possible NHE keys) are not exposed.

### `exports['next_housing']:GetMarkerSettings()`
Returns a ready-to-use marker/settings bundle:

```lua
{
  spritesEnabled = true,
  blipsEnabled = true,
  spriteHeightOffset = 1.0,
  entranceDisplayDistance = 20.0,
  chestDisplayDistance = 2.0,
  stashesEnabled = true,
  stashSystem = "auto",
  stashCustomCoordsEnabled = false,
  stashCustomCoordsMap = {},
  garagesEnabled = true,
  garageShowAllVehicles = true,
  wardrobeEnabled = true,
  wardrobeSystem = "illenium-appearance",
  wardrobeCustomCoordsEnabled = false,
  wardrobeCustomCoordsMap = {},
  housePreviewPlaceholdersEnabled = true
}
```

## Example

```lua
local symbol = exports["next_housing"]:GetSetting("currency_symbol", "$")
local markers = exports["next_housing"]:GetMarkerSettings()

print(("Housing currency: %s | Blips enabled: %s"):format(symbol, tostring(markers.blipsEnabled)))
```
