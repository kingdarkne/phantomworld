if not Employees then

  Employees = {}

end

if not Employees.Server then

  Employees.Server = {}

end

local function HasPermission(permissions, permission)

  for _, perm in ipairs(permissions) do

    if perm == permission then

      return true

    end

  end

  return false

end

local function SetPlayerJobForDealership(identifier, dealershipId, role)

  local location = Locations.Server.GetById(dealershipId)

  if not location or not location.job_name or location.job_name == "" then

    return false

  end

  local job_rank_mapping = location.job_rank_mapping

  if not job_rank_mapping or type(job_rank_mapping) ~= "table" or next(job_rank_mapping) == nil then

    return false

  end

  local jobName

  local jobGrade

  if role then

    jobGrade = GetCaseInsensitive(job_rank_mapping, role)

    if jobGrade == nil then

      return false

    end

    jobName = location.job_name

  else

    jobName = "unemployed"

    jobGrade = 0

  end

  local playerId = Framework.Server.GetPlayerFromIdentifier(identifier)

  if playerId then

    DebugPrint("Setting job for " .. identifier .. "(" .. playerId .. ") to " .. jobName .. " with rank " .. jobGrade, "debug")

    Framework.Server.PlayerSetJob(playerId, jobName, jobGrade)

    return true

  else

    Framework.Server.PlayerSetJobOffline(identifier, jobName, jobGrade)

    return false

  end

end

local function NotifyEmployeeStatusChanged(identifier, dealershipId)

  local playerId = Framework.Server.GetPlayerFromIdentifier(identifier)

  if playerId then

    TriggerClientEvent("jg-dealerships:client:employee-status-changed", playerId, dealershipId)

  end

end

local function GetEmployeePermissionsAndRole(playerId, dealershipId, checkAdmin)

  if checkAdmin == nil then

    checkAdmin = true

  end

  if checkAdmin then

    if Framework.Server.IsAdmin(playerId) then

      DebugPrint(playerId .. " returned as server admin", "debug")

      return {"ADMIN"}, "serverAdmin"

    end

  end

  local identifier = Framework.Server.GetPlayerIdentifier(playerId)

  if not identifier then

    return false, false

  end

  if Config.UseFrameworkJobs then

    local location = Locations.Server.GetById(dealershipId)

    if not location or not location.job_name or location.job_name == "" then

      DebugPrint("Dealership " .. dealershipId .. " has no job_name configured", "debug")

      return false, false

    end

    local playerJob = Framework.Server.GetPlayerJob(playerId)

    if not playerJob or not playerJob.name then

      DebugPrint("Could not get job for player " .. playerId, "debug")

      return false, false

    end

    if playerJob.name ~= location.job_name then

      DebugPrint(identifier .. " job (" .. playerJob.name .. ") does not match dealership job (" .. location.job_name .. ")", "debug")

      return false, false

    end

    local job_rank_permissions = location.job_rank_permissions

    if not job_rank_permissions or type(job_rank_permissions) ~= "table" then

      DebugPrint("No job_rank_permissions configured for dealership " .. dealershipId, "warning")

      local gradeLabel = playerJob.gradeLabel or ("Grade " .. tostring(playerJob.grade))

      return {}, gradeLabel

    end

    local grade = tonumber(playerJob.grade) or 0

    local permissions = job_rank_permissions[tostring(grade)]

    if not permissions then

      DebugPrint("No permissions mapped for grade " .. grade .. " at dealership " .. dealershipId, "debug")

      local gradeLabel = playerJob.gradeLabel or ("Grade " .. tostring(playerJob.grade))

      return {}, gradeLabel

    end

    local gradeLabel = playerJob.gradeLabel or ("Grade " .. tostring(playerJob.grade))

    return permissions, gradeLabel

  end

  local employee = MySQL.single.await("SELECT * FROM dealership_employees WHERE identifier = ? AND dealership = ?", {identifier, dealershipId})

  if not employee then

    DebugPrint(identifier .. " is not an employee at " .. dealershipId, "debug")

    return false, false

  end

  local permissions, roleKey = GetCaseInsensitive(Config.EmployeePermissions, employee.role)

  if not permissions then

    DebugPrint("No permissions configured for role: " .. employee.role, "warning")

    return {}, employee.role

  end

  DebugPrint(identifier .. " is an employee at " .. dealershipId .. " with role " .. employee.role, "debug")

  return permissions, employee.role

end

function Employees.Server.IsEmployee(playerId, dealershipId, requiredPermission, checkAdmin)

  local permissions, role = GetEmployeePermissionsAndRole(playerId, dealershipId, checkAdmin)

  if not permissions then

    return false

  end

  if HasPermission(permissions, "ADMIN") then

    return role

  end

  if not requiredPermission then

    return role

  end

  if type(requiredPermission) == "string" then

    if not HasPermission(permissions, requiredPermission) then

      return false

    end

  elseif type(requiredPermission) == "table" then

    local hasAnyPermission = false

    for _, perm in ipairs(requiredPermission) do

      if HasPermission(permissions, perm) then

        hasAnyPermission = true

        break

      end

    end

    if not hasAnyPermission then

      return false

    end

  end

  return role

end

local function HasEmployeePermission(playerId, dealershipId, permission)

  local permissions = GetEmployeePermissionsAndRole(playerId, dealershipId)

  if not permissions then

    return false

  end

  if HasPermission(permissions, "ADMIN") then

    return true

  end

  return HasPermission(permissions, permission)

end

function Employees.Server.GetPermissions(playerId, dealershipId)

  local permissions = GetEmployeePermissionsAndRole(playerId, dealershipId, true)

  if not permissions then

    return {}

  end

  if HasPermission(permissions, "ADMIN") then

    return {"ADMIN", "MANAGE_EMPLOYEES", "MANAGE_INVENTORY", "MANAGE_FINANCES", "SELL", "DELIVER", "VIEW_RECORDS"}

  end

  return permissions

end

function Employees.Server.GetEmployees(dealershipId)

  local employees = MySQL.query.await("SELECT * FROM dealership_employees WHERE dealership = ? ORDER BY joined DESC", {dealershipId})

  return employees or {}

end

function Employees.Server.HireEmployee(identifier, dealershipId, role)

  local existing = MySQL.single.await("SELECT id FROM dealership_employees WHERE identifier = ? AND dealership = ?", {identifier, dealershipId})

  if existing then

    return false

  end

  MySQL.insert.await("INSERT INTO dealership_employees (identifier, dealership, role) VALUES (?, ?, ?)", {identifier, dealershipId, role})

  local isOnline = SetPlayerJobForDealership(identifier, dealershipId, role)

  if not isOnline then

    NotifyEmployeeStatusChanged(identifier, dealershipId)

  end

  return true

end

function Employees.Server.FireEmployee(identifier, dealershipId)

  local existing = MySQL.single.await("SELECT id FROM dealership_employees WHERE identifier = ? AND dealership = ?", {identifier, dealershipId})

  if not existing then

    return false

  end

  MySQL.query.await("DELETE FROM dealership_employees WHERE identifier = ? AND dealership = ?", {identifier, dealershipId})

  local isOnline = SetPlayerJobForDealership(identifier, dealershipId, nil)

  if not isOnline then

    NotifyEmployeeStatusChanged(identifier, dealershipId)

  end

  return true

end

function Employees.Server.UpdateRole(identifier, dealershipId, newRole)

  local existing = MySQL.single.await("SELECT id FROM dealership_employees WHERE identifier = ? AND dealership = ?", {identifier, dealershipId})

  if not existing then

    return false

  end

  MySQL.query.await("UPDATE dealership_employees SET role = ? WHERE identifier = ? AND dealership = ?", {newRole, identifier, dealershipId})

  local isOnline = SetPlayerJobForDealership(identifier, dealershipId, newRole)

  if not isOnline then

    NotifyEmployeeStatusChanged(identifier, dealershipId)

  end

  return true

end

function Employees.Server.GetEmployeesWithInfo(playerId, dealershipId)

  if not HasEmployeePermission(playerId, dealershipId, "MANAGE_EMPLOYEES") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local employees = Employees.Server.GetEmployees(dealershipId)

  local requesterIdentifier = Framework.Server.GetPlayerIdentifier(playerId)

  for _, employee in ipairs(employees) do

    local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(employee.identifier)

    employee.name = (playerInfo and playerInfo.name) or employee.identifier

    employee.me = (employee.identifier == requesterIdentifier)

  end

  return employees

end

lib.callback.register("jg-dealerships:server:is-employee", function(playerId, dealershipId, checkAdmin)

  local role = Employees.Server.IsEmployee(playerId, dealershipId, nil, checkAdmin)

  if not role then

    return {isEmployee = false}

  end

  local playerInfo = Framework.Server.GetPlayerInfo(playerId)

  local permissions = Employees.Server.GetPermissions(playerId, dealershipId)

  return {

    isEmployee = true,

    employeeName = (playerInfo and playerInfo.name) or "",

    employeeRole = role,

    permissions = permissions

  }

end)

lib.callback.register("jg-dealerships:server:get-dealership-employees", function(playerId, data)

  return Employees.Server.GetEmployeesWithInfo(playerId, data.dealershipId)

end)

RegisterNetEvent("jg-dealerships:server:request-hire-employee", function(data)

  local requesterId = source

  if not HasEmployeePermission(requesterId, data.dealershipId, "MANAGE_EMPLOYEES") then

    Framework.Server.Notify(requesterId, Locale.employeePermissionsError, "error")

    return

  end

  if data.selfHire and data.playerId == requesterId then

    if not Framework.Server.IsAdmin(requesterId) then

      Framework.Server.Notify(requesterId, Locale.onlyServerAdminsCanSelfHire, "error")

      return

    end

    local identifier = Framework.Server.GetPlayerIdentifier(requesterId)

    if not identifier then

      Framework.Server.Notify(requesterId, Locale.playerNotFound, "error")

      return

    end

    if not Employees.Server.HireEmployee(identifier, data.dealershipId, data.role) then

      Framework.Server.Notify(requesterId, Locale.failedToHireEmployee, "error")

      return

    end

    local playerInfo = Framework.Server.GetPlayerInfo(requesterId)

    local playerName = (playerInfo and playerInfo.name) or identifier

    SendWebhook(requesterId, Webhooks.Dealership, "Dealership: Employee Self-Hired", "success", {

      {key = "Dealership", value = data.dealershipId},

      {key = "Employee", value = playerName},

      {key = "Role", value = data.role}

    })

    Framework.Server.Notify(requesterId, Locale.employeeHiredMsg, "success")

    TriggerClientEvent("jg-dealerships:client:employee-hire-response", requesterId, {

      accepted = true,

      playerName = data.playerName,

      identifier = identifier,

      role = data.role

    })

    return

  end

  data.requesterId = requesterId

  TriggerClientEvent("jg-dealerships:client:show-confirm-employment", data.playerId, data)

end)

RegisterNetEvent("jg-dealerships:server:employee-hire-rejected", function(requesterId, playerName)

  Framework.Server.Notify(requesterId, Locale.employeeRejectedMsg, "error")

  TriggerClientEvent("jg-dealerships:client:employee-hire-response", requesterId, {

    accepted = false,

    playerName = playerName

  })

end)

RegisterNetEvent("jg-dealerships:server:hire-employee", function(data)

  local identifier = Framework.Server.GetPlayerIdentifier(data.playerId)

  if not identifier then

    Framework.Server.Notify(data.requesterId, Locale.playerNotFound, "error")

    TriggerClientEvent("jg-dealerships:client:employee-hire-response", data.requesterId, {

      accepted = false,

      playerName = data.playerName

    })

    return

  end

  DebugPrint("Hiring employee " .. identifier .. "(" .. data.playerId .. ") at " .. data.dealershipId .. " with role " .. data.role, "debug")

  if not Employees.Server.HireEmployee(identifier, data.dealershipId, data.role) then

    Framework.Server.Notify(data.requesterId, Locale.failedToHireEmployee, "error")

    TriggerClientEvent("jg-dealerships:client:employee-hire-response", data.requesterId, {

      accepted = false,

      playerName = data.playerName

    })

    return

  end

  local playerInfo = Framework.Server.GetPlayerInfo(data.playerId)

  local playerName = (playerInfo and playerInfo.name) or identifier

  SendWebhook(source, Webhooks.Dealership, "Dealership: Employee Hired", "success", {

    {key = "Dealership", value = data.dealershipId},

    {key = "Employee", value = playerName},

    {key = "Role", value = data.role}

  })

  Framework.Server.Notify(data.requesterId, Locale.employeeHiredMsg, "success")

  TriggerClientEvent("jg-dealerships:client:employee-hire-response", data.requesterId, {

    accepted = true,

    playerName = data.playerName,

    identifier = identifier,

    role = data.role

  })

end)

RegisterNetEvent("jg-dealerships:server:fire-employee", function(identifier, dealershipId)

  local requesterId = source

  if not HasEmployeePermission(requesterId, dealershipId, "MANAGE_EMPLOYEES") then

    Framework.Server.Notify(requesterId, Locale.employeePermissionsError, "error")

    return

  end

  local employeeInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)

  local employeePlayerId = Framework.Server.GetPlayerFromIdentifier(identifier)

  if not Employees.Server.FireEmployee(identifier, dealershipId) then

    Framework.Server.Notify(requesterId, Locale.failedToFireEmployee, "error")

    return

  end

  if employeePlayerId then

    local message = string.gsub(Locale.firedNotification, "%%{value}", dealershipId)

    Framework.Server.Notify(employeePlayerId, message, "error")

  end

  local employeeName = (employeeInfo and employeeInfo.name) or identifier

  SendWebhook(requesterId, Webhooks.Dealership, "Dealership: Employee Fired", "danger", {

    {key = "Dealership", value = dealershipId},

    {key = "Employee", value = employeeName}

  })

end)

RegisterNetEvent("jg-dealerships:server:update-employee-role", function(identifier, dealershipId, newRole)

  local requesterId = source

  if not HasEmployeePermission(requesterId, dealershipId, "MANAGE_EMPLOYEES") then

    Framework.Server.Notify(requesterId, Locale.employeePermissionsError, "error")

    return

  end

  if not Employees.Server.UpdateRole(identifier, dealershipId, newRole) then

    Framework.Server.Notify(requesterId, Locale.failedToUpdateEmployeeRole, "error")

    return

  end

  local employeeInfo = Framework.Server.GetPlayerInfoFromIdentifier(identifier)

  local employeeName = (employeeInfo and employeeInfo.name) or identifier

  SendWebhook(requesterId, Webhooks.Dealership, "Dealership: Employee Updated", nil, {

    {key = "Dealership", value = dealershipId},

    {key = "Employee", value = employeeName},

    {key = "New role", value = newRole}

  })

end)
