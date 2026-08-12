Config = {}

-- Owner identifiers (match server.cfg principals)
Config.OwnerIdentifiers = {
    ['fivem:14311541'] = true,
    ['fivem:13816790'] = true,
    ['discord:413173364216168449'] = true,
    ['discord:769964740008083526'] = true,
    ['license:5d42954dcf1e1e2444564e7f456d89ebc6c8ca76'] = true,
    ['license2:5d42954dcf1e1e2444564e7f456d89ebc6c8ca76'] = true,
}

-- Also treat anyone with these ACEs as owner (covers qbcore.god inheritance)
Config.OwnerAces = {
    'qbcore.god',
    'group.superadmin',
}

Config.TextOffsetZ = 1.05
Config.TextScale = 0.35
Config.TextColor = { r = 255, g = 215, b = 0, a = 255 }
Config.TextOutline = true
Config.LabelTemplate = '[OWNER] {name}'
