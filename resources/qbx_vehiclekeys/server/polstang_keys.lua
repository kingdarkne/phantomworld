local POLSTANG = joaat('2015polstang')

--- Blocks key grants for `2015polstang` unless the vehicle has a statebag owner matching the player.
--- Unowned spawns (e.g. raw vMenu) never receive keys from server events.
---@param src number
---@param vehicle number
---@return boolean `true` if keys must not be granted
function PolstangDenyKeyGrant(src, vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return true end
    if GetEntityModel(vehicle) ~= POLSTANG then return false end
    local owner = Entity(vehicle).state.owner
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return true end
    if not owner then return true end
    return owner ~= player.PlayerData.citizenid
end
