--[[
    Qbox runs `qbx_core` and (with `stop qb-core`) does not start the legacy `qb-core` resource.
    `qbx_core` still provides `exports['qb-core']` and satisfies `dependency 'qb-core'` via `provide 'qb-core'`,
    but `GetResourceState('qb-core')` refers to the old resource name and stays `stopped`.

    Use this instead of only checking `GetResourceState('qb-core')` when gating QB-style framework logic.
    Optional: in other resources add to fxmanifest — shared_scripts { '@qbx_core/shared/qb_compat.lua' }
]]

--- @return boolean true if legacy qb-core or Qbox (qbx_core) is running.
function isQbFrameworkStarted()
    return GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started'
end
