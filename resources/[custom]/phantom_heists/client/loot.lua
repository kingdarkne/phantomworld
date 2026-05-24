-- Loot carrying system
local carryingLoot = 0
local maxLootCarry = 3
local lootBag = nil

-- Drop loot on death
RegisterNetEvent('phantom_heists:client:playerDied', function()
    if carryingLoot > 0 then
        carryingLoot = 0
        if lootBag and DoesEntityExist(lootBag) then
            DeleteObject(lootBag)
            lootBag = nil
        end
        lib.notify({ title = 'Loot Dropped', description = 'You dropped all loot bags!', type = 'error' })
    end
end)

-- Attach loot bag to player
function AttachLootBag()
    if lootBag and DoesEntityExist(lootBag) then
        DeleteObject(lootBag)
    end
    local ped = PlayerPedId()
    local model = GetHashKey('prop_cs_heist_bag_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    lootBag = CreateObject(model, 0, 0, 0, true, true, true)
    AttachEntityToEntity(lootBag, ped, GetPedBoneIndex(ped, 24818), -0.25, -0.55, 0.0, 0.0, 90.0, 180.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

-- Remove loot bag
function RemoveLootBag()
    if lootBag and DoesEntityExist(lootBag) then
        DeleteObject(lootBag)
        lootBag = nil
    end
end
