Config = {}

-- Mark which identifiers should be treated as "Owner".
-- Your FiveM ID from server.cfg is 14311541, so we use that here.
Config.OwnerIdentifiers = {
    ['fivem:14311541'] = true,
}

-- 3D text settings
Config.TextOffsetZ = 1.0        -- how high above the head
Config.TextScale = 0.35
Config.TextColor = { r = 255, g = 215, b = 0, a = 255 } -- gold color
Config.TextOutline = true

-- Label format. {name} will be replaced with Firstname Lastname.
Config.LabelTemplate = '[OWNER] {name}'

