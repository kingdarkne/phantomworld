return {
    stress = {
        enableStress = true, -- If false, it will disable stress for everyone
    },

    menu = { -- Don't touch
        isOutMapChecked = false, -- isOutMapChecked
        isOutCompassChecked = false, -- isOutMapChecked
        isCompassFollowChecked = true, -- isCompassFollowChecked
        isMapNotifChecked = true, -- isMapNotifChecked
        isLowFuelChecked = true, -- isLowFuelChecked
        isCinematicNotifChecked = true, -- isCinematicNotifChecked
        isDynamicHealthChecked = true, -- isDynamicHealthChecked
        isDynamicArmorChecked= true, -- isDynamicArmorChecked
        isDynamicHungerChecked = true, -- isDynamicHungerChecked
        isDynamicThirstChecked = true, -- isDynamicThirstChecked
        isDynamicStressChecked = true, -- isDynamicStressChecked
        isDynamicOxygenChecked = true, -- isDynamicOxygenChecked
        isChangeFPSChecked = true, -- isChangeFPSChecked
        isHideMapChecked = false, -- isHideMapChecked
        isToggleMapBordersChecked = true, -- isToggleMapBordersChecked
        isDynamicEngineChecked = true, -- isDynamicEngineChecked
        isDynamicNitroChecked = true, -- isDynamicNitroChecked
        isChangeCompassFPSChecked = true, -- isChangeCompassFPSChecked
        isCompassShowChecked = true, -- isShowCompassChecked
        isShowStreetsChecked = true, -- isShowStreetsChecked
        isPointerShowChecked = true, -- isPointerShowChecked
        isDegreesShowChecked = true, -- isDegreesShowChecked
        isCineamticModeChecked = false, -- isCineamticModeChecked
        isToggleMapShapeChecked = 'square', -- isToggleMapShapeChecked
    },

    -- Enhanced HUD Settings
    hud = {
        enableMinimalMode = false, -- Enable minimal HUD mode
        enableAnimatedBars = true, -- Enable animated status bars
        enableCircularHealth = false, -- Enable circular health indicator
        enableVehicleInfo = true, -- Show vehicle info (speed, fuel)
        enableLocationInfo = true, -- Show current location/street
        enableMoneyDisplay = true, -- Show money display
        enableJobDisplay = true, -- Show job info
        enableVoiceIndicator = true, -- Show voice activity indicator
        enableTalkingIndicator = true, -- Show who is talking
        enableRadioIndicator = true, -- Show radio indicator
    },

    -- Color customization
    colors = {
        health = '#ff4444', -- Health bar color
        armor = '#4444ff', -- Armor bar color
        hunger = '#ffaa44', -- Hunger bar color
        thirst = '#44aaff', -- Thirst bar color
        stress = '#ff44ff', -- Stress bar color
        oxygen = '#44ff44', -- Oxygen bar color
        engine = '#ffffff', -- Engine health color
    },

    -- Position customization
    positions = {
        statusBars = 'left', -- left, right, bottom
        money = 'top-right', -- top-left, top-right, bottom-left, bottom-right
        job = 'top-left', -- top-left, top-right, bottom-left, bottom-right
        vehicle = 'bottom-right', -- top-left, top-right, bottom-left, bottom-right
    }
}