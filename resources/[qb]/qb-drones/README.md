# Drone Script for FiveM (QBCore)

This script allows players to control drones in a **FiveM** server using the **QBCore** framework. The drone can be used for a variety of purposes such as cinematics, exploration, or fun interactions with other players in the game.

## Features

- **Full drone control**.
- **First-person camera** to simulate the drone's perspective.
- Ability to control **speed, altitude, and direction** of the drone.
- Customizable **drone model** and **control settings**.
- Easy integration with QBCore framework for server owners.
- Additional features that can be enabled or disabled for the drone:
  - **Infrared / Heat Vision**: Toggle infrared vision for better visibility in low light or through walls.
  - **Night Vision**: Activate night vision for enhanced visibility in dark environments.
  - **Boost**: Temporarily boost the drone’s speed for quick maneuvers.
  - **Tazer**: Fire a tazer from the drone to incapacitate enemies.
  - **Explosive**: Activate an explosive device from the drone for high-impact actions.


## **Configure the drone model (optional)**:
   - The script may come with a default drone models (vanilla drones stream). If you want to use a custom model, add the model to the `stream` folder in `drones_stream`, then change the name of the model in `config.lua`.

## Controls

- **Ascend**: Hold `Space` to ascend.
- **Descend**: Hold `Shift` to descend.
- **Move forward**: Hold `W` to move forward.
- **Move backward**: Hold `S` to move backward.
- **Move left**: Hold `A` to move to the left.
- **Move right**: Hold `D` to move to the right.
- **Heading**: Use the `mouse` to head the drone's direction.
- **Zoom**: Use the `mouse wheel` to adjust the zoom from **x1** to **x16**.
- **Homing**: Press `Home` to make the drone return to the player automatically.
- **Center the camera**: Press `Supr` to center the drone camera.
- **Infrared/Heat-vision**: Toggle with `F`.
- **Night vision**: Toggle with `R`.
- **Tazer**: Press `1`.
- **Explode**: Press `2`.
- **Boost**: Press `3`.
- **Disconect**: Press `ESC`.

## Configuration

You can adjust the drone settings in the `config.lua` file located in the `dd-drone` resource folder. Common configurable options for each drone include:

```lua
    -- Drone example settings
    label = "Drone",                                        -- Visible text.
    name = "drone",                                         -- Item name.
    public = true,                                          -- Can be used anybody?
    price = 10000,                                          -- Price in store
    model = GetHashKey('ch_prop_arcade_drone_01b'),         -- Model from drones_stream > stream
    stats = {
    speed   = 1.0,               -- Max speed multiplier
    agility = 1.0,               -- Acceleration/deceleration multiplier
    range   = 100.0,             -- Range (drone display begins fading out when leaving range)

    -- Max Stats:
    maxSpeed    = 2,             
    maxAgility  = 2,
    maxRange    = 200,
    },
    abilities = {
    infrared     = false,   -- Infrared/heat-vision
    nightvision = false,    -- Nightvision
    boost       = false,    -- Boost
    tazer       = false,    -- Tazer 
    explosive   = false,    -- Explosion
    },
    restrictions = {},  -- Enter job names in here (e.g: {'police','mechanic'}) to restrict the drone purchase to these jobs only, or leave it empty (e.g: {}) for no job restrictions.
    singleuse = false   -- The drone will disappear after the first use.
```