-- Phantom Core - UI Dialog System
-- High-quality dialog box for confirmations and inputs

local activeDialog = nil
local dialogCallbacks = {}

-- Show input dialog
function ShowInputDialog(options)
    if activeDialog then
        return false, 'Dialog already active'
    end
    
    options = options or {}
    local id = options.id or 'phantom_dialog_' .. GetGameTimer()
    local title = options.title or 'Input'
    local inputs = options.inputs or {}
    local callback = options.callback
    
    -- Validate inputs
    for i, input in ipairs(inputs) do
        inputs[i].type = input.type or 'text'
        inputs[i].label = input.label or 'Input'
        inputs[i].placeholder = input.placeholder or ''
        inputs[i].default = input.default or ''
        inputs[i].required = input.required or false
        inputs[i].password = input.password or false
    end
    
    -- Store callback
    if callback then
        dialogCallbacks[id] = callback
    end
    
    -- Send to NUI
    SendNUIMessage({
        action = 'showDialog',
        id = id,
        title = title,
        type = 'input',
        inputs = inputs
    })
    
    activeDialog = {
        id = id,
        title = title,
        type = 'input'
    }
    
    SetNuiFocus(true, true)
    
    return true
end

-- Show confirmation dialog
function ShowConfirmDialog(options)
    if activeDialog then
        return false, 'Dialog already active'
    end
    
    options = options or {}
    local id = options.id or 'phantom_dialog_' .. GetGameTimer()
    local title = options.title or 'Confirm'
    local message = options.message or 'Are you sure?'
    local confirmText = options.confirmText or 'Confirm'
    local cancelText = options.cancelText or 'Cancel'
    local callback = options.callback
    
    -- Store callback
    if callback then
        dialogCallbacks[id] = callback
    end
    
    -- Send to NUI
    SendNUIMessage({
        action = 'showDialog',
        id = id,
        title = title,
        type = 'confirm',
        message = message,
        confirmText = confirmText,
        cancelText = cancelText
    })
    
    activeDialog = {
        id = id,
        title = title,
        type = 'confirm'
    }
    
    SetNuiFocus(true, true)
    
    return true
end

-- Close dialog
function CloseDialog()
    if not activeDialog then return end
    
    SendNUIMessage({
        action = 'hideDialog'
    })
    
    SetNuiFocus(false, false)
    
    -- Clear callback
    dialogCallbacks[activeDialog.id] = nil
    
    activeDialog = nil
end

-- NUI Callbacks
RegisterNUICallback('dialogSubmitted', function(data, cb)
    local callback = dialogCallbacks[data.id]
    
    if callback then
        callback(data.values, true)
    end
    
    CloseDialog()
    cb({})
end)

RegisterNUICallback('dialogCancelled', function(data, cb)
    local callback = dialogCallbacks[data.id]
    
    if callback then
        callback(nil, false)
    end
    
    CloseDialog()
    cb({})
end)

-- Export functions
exports('ShowInputDialog', ShowInputDialog)
exports('ShowConfirmDialog', ShowConfirmDialog)
exports('CloseDialog', CloseDialog)

-- Debug commands
if Config.Debug then
    RegisterCommand('testinput', function()
        ShowInputDialog({
            title = 'Test Input',
            inputs = {
                {
                    type = 'text',
                    label = 'Name',
                    placeholder = 'Enter your name',
                    required = true
                },
                {
                    type = 'number',
                    label = 'Age',
                    placeholder = 'Enter your age',
                    required = true
                },
                {
                    type = 'text',
                    label = 'Password',
                    placeholder = 'Enter password',
                    password = true
                }
            },
            callback = function(values, submitted)
                if submitted then
                    print('Submitted:', json.encode(values))
                else
                    print('Cancelled')
                end
            end
        })
    end)
    
    RegisterCommand('testconfirm', function()
        ShowConfirmDialog({
            title = 'Test Confirmation',
            message = 'Are you sure you want to proceed?',
            confirmText = 'Yes',
            cancelText = 'No',
            callback = function(values, confirmed)
                if confirmed then
                    print('Confirmed')
                else
                    print('Cancelled')
                end
            end
        })
    end)
end

DebugPrint('Dialog system loaded')
