function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end


local currentResourceName = GetCurrentResourceName()

local debugIsEnabled = GetConvarInt(('%s-debugMode'):format(currentResourceName), 0) == 1

function debugPrint(...)
    if not debugIsEnabled then return end
    local args <const> = { ... }

    local appendStr = ''
    for _, v in ipairs(args) do
        appendStr = appendStr .. ' ' .. tostring(v)
    end
    local msgTemplate = '^3[%s]^0%s'
    local finalMsg = msgTemplate:format(currentResourceName, appendStr)
    print(finalMsg)
end

RegisterNUICallback("loadUtils", function(data, cb)
    cb({
        locale = GetAllLocales(),
        config = {
            shop = Config.shop,
            currency = Config.currency,
            weaponModels = Config.weaponModels,
            speedMetric = Config.speedMetric,
            priceDeduction = Config.priceDeduction,
            recruitDialog = Config.recruitDialog,
            playersProvideWeapons = Config.playersProvideWeapons,
            recruit = Config.recruit,
            maxSlots = Config.maxSlots,
        },
        theme = Config.uiColors
    })
end)

function HelpText(msg)
    lib.showTextUI(msg)
end

function Notify(text, type)
    lib.notify({
        title = L("bodyguards"),
        description = text,
        type = type
    })
end

function GetWorldCoordsFromScreen()
    local camCoords = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local dir = RotToDir(rot)
    local endPoint = camCoords + dir*75
    local raycast = StartExpensiveSynchronousShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, endPoint.x, endPoint.y, endPoint.z, 1, PlayerPedId(), 4)
    local result, hit, coords = GetShapeTestResult(raycast)

    return coords
end

function RotToDir(rot)
    return vector3(
        -math.sin((math.pi / 180) * rot.z) * math.abs(math.cos((math.pi / 180) * rot.x)),
        math.cos((math.pi / 180) * rot.z) * math.abs(math.cos((math.pi / 180) * rot.x)),
        math.sin((math.pi / 180) * rot.x)
    )
end

function ToggleNuiFrame(shouldShow)
    SetNuiFocus(shouldShow, shouldShow)
    SendReactMessage('setVisible', shouldShow)
end

function GetModelIndex(model)
    for k, v in pairs(Config.shop) do
        for i=1,#Config.shop[k] do
            if(Config.shop[k][i].ped == model) then
                return i, k
            end
        end
    end
end