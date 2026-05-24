Cores = {
    { -- New ESX
        Name = "ESX",
        ResourceName = "es_extended",
        GetFramework = function() return exports["es_extended"]:getSharedObject() end
    },
    -- { -- Old ESX
    --     Name = "ESX",
    --     ResourceName = "es_extended",
    --     GetFramework = function() ESX = nil while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) end return ESX end
    -- },
    -- Prefer Qbox first: qbx_core is the primary framework
    {
        Name = "QBXCore",
        ResourceName = "qbx_core",
        -- QBX-native (works with qbx:enablebridge false): thin QBCore-shaped wrapper
        GetFramework = function()
            return {
                Functions = {
                    GetPlayerData = function()
                        return exports.qbx_core:GetPlayerData()
                    end,
                },
            }
        end
    },
    }