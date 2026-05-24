return {
    doctorCallCooldown = 1, -- Time in minutes for cooldown between doctors calls
    wipeInvOnRespawn = true, -- Enable to disable removing all items from player on respawn
    depositSociety = function(society, amount)
        local ok, err = pcall(function()
            exports['Renewed-Banking']:addAccountMoney(society, amount)
        end)
        if not ok then
            print('[qbx_ambulancejob] depositSociety failed: ' .. tostring(err))
        end
    end
}