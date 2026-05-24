Cores = {
    {
        Name = "ESX",
        ResourceName = "es_extended",
        GetFramework = function() return exports["es_extended"]:getSharedObject() end
    },
    {
        Name = "QBXCore",
        ResourceName = "qbx_core",
        GetFramework = function()
            local core = DrGetQBCore()
            if core then return core end
            return {
                Functions = {
                    GetPlayerData = function()
                        return exports.qbx_core:GetPlayerData()
                    end,
                },
            }
        end
    },
    {
        Name = "QBCore",
        ResourceName = "qb-core",
        GetFramework = function()
            return DrGetQBCore()
        end
    },
}