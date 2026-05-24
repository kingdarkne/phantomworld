# Client API - Interfaces

## Core Exports

### `exports['next_housing']:GetApiVersion()`
Returns API version string.

### `exports['next_housing']:IsApiReady()`
Returns `true/false` based on framework/player readiness.

### `exports['next_housing']:GetContext()`
Returns:

```lua
{
  apiVersion = "1.1.0",
  framework = "esx|qbcore|qbox|unknown",
  frameworkReady = true/false,
  playerReady = true/false,
  locale = "fr",
  localeLoaded = true/false,
  uiOpen = true/false
}
```

### `exports['next_housing']:GetLocale()`
Returns the active client locale (for example `en`, `fr`).

### `exports['next_housing']:GetTranslations([locale])`
Returns the translation table for the requested locale.

### `exports['next_housing']:GetMarkerSettings()`
Returns the current local marker/settings snapshot.

### `exports['next_housing']:RequestMarkerSettings(cb)`
Requests an updated marker/settings bundle from the native settings flow.

```lua
cb(markerSettings)
```

## UI Open/Close

### `exports['next_housing']:OpenAdminInterface(cb)`
Open admin UI (permission check included).

```lua
cb(success, reason)
```

### `exports['next_housing']:OpenHousingInterface(cb)`
Open standard housing UI.

### `exports['next_housing']:OpenJobInterface(cb)`
Open agency/job interface flow.

### `exports['next_housing']:OpenPapInterface(cb)`
Open PAP interface flow.

### `exports['next_housing']:OpenWardrobeInterface(cb)`
Open wardrobe if available.

### `exports['next_housing']:TriggerOpenWardrobe()`
Compatibility export that directly triggers the wardrobe open flow.

### `exports['next_housing']:OpenGarageInterface(options, cb)`
Open garage flow. Supports:
- manual coords mode;
- houseId-only mode (coords auto resolved from house).

`options`:

```lua
{
  action = "garage" or "store", -- optional, default garage
  houseId = 12,                 -- required
  x = 1.0, y = 2.0, z = 3.0, h = 90.0
  -- or:
  -- coords = { x = 1.0, y = 2.0, z = 3.0, h = 90.0 }
}
```

### `exports['next_housing']:CloseInterface()`
Close Next Housing NUI.

### `exports['next_housing']:IsInterfaceOpen()`
Returns `true/false`.

## Example

```lua
RegisterCommand("nh_open_admin", function()
    exports["next_housing"]:OpenAdminInterface(function(success, reason)
        print(("admin ui success=%s reason=%s"):format(tostring(success), tostring(reason)))
    end)
end)

RegisterCommand("nh_open_garage_auto", function()
    exports["next_housing"]:OpenGarageInterface({
        houseId = 12,
        action = "garage"
    }, function(success, reason)
        print(("garage open success=%s reason=%s"):format(tostring(success), tostring(reason)))
    end)
end)

RegisterCommand("nh_markers_snapshot", function()
    exports["next_housing"]:RequestMarkerSettings(function(bundle)
        print(("sprites=%s blips=%s"):format(
            tostring(bundle and bundle.spritesEnabled),
            tostring(bundle and bundle.blipsEnabled)
        ))
    end)
end)
```
