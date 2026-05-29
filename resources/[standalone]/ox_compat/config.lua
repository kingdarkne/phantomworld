Config = {}

Config.Modules = {
    ['qb-menu'] = {
        active = true, -- Do you need this module to be enabled?
        resource_name = 'qb-menu' -- What is the name of the resource that provided this module? (In case you changed its name)
    },
    ['qb-input'] = {
        active = true, -- Do you need this module to be enabled?
        resource_name = 'qb-input' -- What is the name of the resource that provided this module? (In case you changed its name)
    },
    ['qb-target'] = {
        active = true, -- Do you need this module to be enabled?
        resource_name = 'qb-target' -- What is the name of the resource that provided this module? (In case you changed its name)
    },
}

Config.InventoryName = 'qs-inventory'

local qbCore

--- Lazy-load qbx_core so ox_compat can start before qbx_core (targeting.cfg early pass).
function GetQBCore()
    if qbCore then return qbCore end
    if GetResourceState('qbx_core') ~= 'started' then return nil end
    qbCore = exports['qbx_core']:GetCoreObject()
    return qbCore
end
