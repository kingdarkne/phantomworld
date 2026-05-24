if not TrailerAttachment then

    TrailerAttachment = {}

end

if not TrailerAttachment.Client then

    TrailerAttachment.Client = {}

end

local smallTrailer = nil

local mediumTrailer = nil

function TrailerAttachment.Client.GetVehicleSizeCategory(vehicleModel)

    if not vehicleModel then

        return nil

    end

    local modelHash = type(vehicleModel) == "string" and GetHashKey(vehicleModel) or vehicleModel

    if not IsModelValid(modelHash) or not IsModelAVehicle(modelHash) then

        return nil

    end

    local vehicleClass = GetVehicleClassFromName(modelHash)

    if vehicleClass == 8 or vehicleClass == 13 then
        return "small"

    elseif vehicleClass == 0 or vehicleClass == 1 or vehicleClass == 2 or vehicleClass == 3 or vehicleClass == 4 or vehicleClass == 5 or vehicleClass == 6 or vehicleClass == 7 or vehicleClass == 9 then

        return "medium"

    elseif vehicleClass == 10 or vehicleClass == 11 or vehicleClass == 12 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 or vehicleClass == 17 or vehicleClass == 18 or vehicleClass == 19 or vehicleClass == 20 then

        return "large"

    end

    return "medium"
end

function TrailerAttachment.Client.AttachVehicleToTrailer(trailer, vehicle, vehicleModel)

    if not trailer or not DoesEntityExist(trailer) then

        return false, nil, nil

    end

    local sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(vehicleModel)

    if not sizeCategory or sizeCategory == "large" then

        return false, nil, nil

    end

    local attachmentData = nil

    if sizeCategory == "small" then

        attachmentData = smallTrailer

    else

        attachmentData = mediumTrailer

    end

    if not attachmentData then

        return false, nil, nil

    end

    AttachEntityToEntity(

        vehicle,

        trailer,

        0,

        attachmentData.offset.x,

        attachmentData.offset.y,

        attachmentData.offset.z,

        attachmentData.rotation.x,

        attachmentData.rotation.y,

        attachmentData.rotation.z,

        false,

        false,

        false,

        false,

        2,

        true

    )

    return true, attachmentData, sizeCategory

end

function TrailerAttachment.Client.DetachVehicleFromTrailer(vehicle)

    if not vehicle or not DoesEntityExist(vehicle) then

        return false

    end

    DetachEntity(vehicle, true, true)

    return true

end

function TrailerAttachment.Client.IsVehicleAttached(vehicle)

    if not vehicle or not DoesEntityExist(vehicle) then

        return false

    end

    return IsEntityAttached(vehicle)

end

local function InitializeTrailerData()

    smallTrailer = {

        offset = vector3(0.0, -2.0, 0.5),

        rotation = vector3(0.0, 0.0, 0.0)

    }

    mediumTrailer = {

        offset = vector3(0.0, -1.0, 0.8),

        rotation = vector3(0.0, 0.0, 0.0)

    }

end

CreateThread(function()

    InitializeTrailerData()

end)

exports('GetVehicleSizeCategory', TrailerAttachment.Client.GetVehicleSizeCategory)

exports('AttachVehicleToTrailer', TrailerAttachment.Client.AttachVehicleToTrailer)

exports('DetachVehicleFromTrailer', TrailerAttachment.Client.DetachVehicleFromTrailer)

exports('IsVehicleAttached', TrailerAttachment.Client.IsVehicleAttached)
