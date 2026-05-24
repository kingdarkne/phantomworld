--[[
    Dracula pack: Qbox-compatible helpers (no standalone qb-core resource required).
    Include in other resources: shared_scripts { '@dr-qbx-compat/shared.lua', ... }
]]

---@return table|nil
function DrGetQBCore()
    if GetResourceState('qbx_core') == 'started' then
        local ok, obj = pcall(function()
            return exports.qbx_core:GetCoreObject()
        end)
        if ok and obj then return obj end
    end
    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    return ok and obj or nil
end

--- Client-only draw text (qb-core DrawText or ox_lib showTextUI).
---@param text string
---@param position? string
function DrDrawText(text, position)
    if IsDuplicityVersion() then return end
    if GetResourceState('ox_lib') == 'started' then
        local ok = pcall(function()
            lib.showTextUI(text)
        end)
        if ok then return end
    end
    pcall(function()
        exports['qb-core']:DrawText(text, position or 'left')
    end)
end

function DrHideText()
    if IsDuplicityVersion() then return end
    if GetResourceState('ox_lib') == 'started' then
        local ok = pcall(function()
            lib.hideTextUI()
        end)
        if ok then return end
    end
    pcall(function()
        exports['qb-core']:HideText()
    end)
end
