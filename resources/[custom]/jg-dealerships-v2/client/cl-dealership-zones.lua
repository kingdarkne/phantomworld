if not DealershipZones then

    DealershipZones = {}

end

if not DealershipZones.Client then

    DealershipZones.Client = {}

end

local activeZones = {}

local zoneInteractions = {}

local zoneBlips = {}

local currentZone = nil

local function CalculateBoundingBox(points)

    if not points or #points == 0 then

        return vec3(0, 0, 0), vec3(0, 0, 0)

    end

    local minX, minY, minZ = math.huge, math.huge, math.huge

    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for _, point in ipairs(points) do

        minX = math.min(minX, point.x)

        minY = math.min(minY, point.y)

        minZ = math.min(minZ, point.z)

        maxX = math.max(maxX, point.x)

        maxY = math.max(maxY, point.y)

        maxZ = math.max(maxZ, point.z)

    end

    minZ = minZ - 5.0

    maxZ = maxZ + 10.0

    return vec3(minX, minY, minZ), vec3(maxX, maxY, maxZ)

end

function DealershipZones.Client.CreateZone(dealershipId, zoneData, interactionType, onEnter, onExit)

    if not zoneData or not zoneData.points then

        return false

    end

    local minBound, maxBound = CalculateBoundingBox(zoneData.points)

    local zone = lib.zones.poly({

        points = zoneData.points,

        thickness = zoneData.thickness or 10.0,

        debug = Config.DebugZones or false,

        onEnter = function()

            currentZone = dealershipId

            if onEnter then

                onEnter(dealershipId)

            end

        end,

        onExit = function()

            currentZone = nil

            if onExit then

                onExit(dealershipId)

            end

        end

    })

    activeZones[dealershipId] = activeZones[dealershipId] or {}

    table.insert(activeZones[dealershipId], zone)

    return zone

end

function DealershipZones.Client.RemoveZone(dealershipId)

    if not activeZones[dealershipId] then

        return false

    end

    for _, zone in ipairs(activeZones[dealershipId]) do

        zone:remove()

    end

    activeZones[dealershipId] = nil

    return true

end

function DealershipZones.Client.RemoveAllZones()

    for dealershipId, zones in pairs(activeZones) do

        for _, zone in ipairs(zones) do

            zone:remove()

        end

    end

    activeZones = {}

end

function DealershipZones.Client.GetCurrentZone()

    return currentZone

end

function DealershipZones.Client.IsInZone(dealershipId)

    return currentZone == dealershipId

end

function DealershipZones.Client.CreateBlip(dealershipId, coords, blipData)

    if not coords or not blipData then

        return nil

    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, blipData.sprite or 326)

    SetBlipDisplay(blip, blipData.display or 4)

    SetBlipScale(blip, blipData.scale or 0.8)

    SetBlipColour(blip, blipData.color or 3)

    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")

    AddTextComponentSubstringPlayerName(blipData.name or "Dealership")

    EndTextCommandSetBlipName(blip)

    zoneBlips[dealershipId] = blip

    return blip

end

function DealershipZones.Client.RemoveBlip(dealershipId)

    if zoneBlips[dealershipId] then

        RemoveBlip(zoneBlips[dealershipId])

        zoneBlips[dealershipId] = nil

        return true

    end

    return false

end

function DealershipZones.Client.RemoveAllBlips()

    for dealershipId, blip in pairs(zoneBlips) do

        RemoveBlip(blip)

    end

    zoneBlips = {}

end

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        DealershipZones.Client.RemoveAllZones()

        DealershipZones.Client.RemoveAllBlips()

    end

end)
