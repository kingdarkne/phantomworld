Config = {}

-- Block health loss from empty hunger/thirst (and optional sleep/fatigue statebags if present).
Config.DisableNeedDamage = true

-- If hunger/thirst hit 0, bump back to this so HUD shows "empty" without triggering other scripts that require > 0.
-- Set to 0 to allow true zero on the HUD (damage is still blocked).
Config.MinHungerThirst = 0
