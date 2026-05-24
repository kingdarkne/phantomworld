Globals = {}

Functions = {}

Locale = Locales[Config.Locale or "en"]

Globals.InteractionZOffset = 1.0

exports("locale", function() return Locale end)

exports("config", function() return Config end)

function DebugPrint(text, debugtype, ...)

  if not Config.Debug then return end

  local prefix = "^2[DEBUG]^7"

  if debugtype == "warning" then prefix = "^3[WARNING]^7" end 

  local args = {...}

  local output = ""

  for i = 1, #args do

    if type(args[i]) == "table" then

      output = output .. json.encode(args[i])

    elseif type(args[i]) ~= "string" then

      output = output .. tostring(args[i])

    else

      output = output .. args[i]

    end

    if i ~= #args then output = output .. " " end

  end

  print(prefix, text, output)

end

function JGDeleteVehicle(vehicle)

  if not DoesEntityExist(vehicle) then return end

  if GetResourceState("AdvancedParking") == "started" then

    exports["AdvancedParking"]:DeleteVehicle(vehicle, false)

  else

    DeleteEntity(vehicle)

  end

end

function SetVehiclePlateText(vehicle, plate)

  if GetResourceState("AdvancedParking") == "started" then

    exports["AdvancedParking"]:UpdatePlate(vehicle, plate)

  else

    SetVehicleNumberPlateText(vehicle, plate)

  end

end

function ConvertModelToHash(model)

  return type(model) == "string" and joaat(model) or model
end

function IsValidGTAPlate(plate)

  if #plate <= 8 and plate:match("^[%w%s]*$") then return true end

  return false

end

function TableKeys(table)

  if not table then return {} end

  local keys = {}

  for k, _ in pairs(table) do

    keys[#keys+1] = k  

  end

  return keys

end

function Round(num, dp)

  dp = dp or 0

  local mult = 10^(dp or 0)

  return math.floor(num * mult + 0.5) / mult

end

function IsItemInList(list, item)

  if #list == 0 then

    return true

  end

  for _, value in ipairs(list) do

    if value == item then

      return true

    end

  end

  return false

end

function Trim(s)

  return (s:gsub("^%s*(.-)%s*$", "%1"))

end

function TableValues(table)

  local values = {}

  for _, val in pairs(table) do

    values[#values+1] = val

  end

  return values

end

function GetCaseInsensitive(tbl, key)

  if not tbl or not key then return nil, nil end

  if tbl[key] ~= nil then return tbl[key], key end

  local lowerKey = string.lower(key)

  for k, v in pairs(tbl) do

    if type(k) == "string" and string.lower(k) == lowerKey then

      return v, k

    end

  end

  return nil, nil

end

function CheckJobGangWhitelist(whitelist, name, grade)

  if not whitelist or not next(whitelist) then return true end

  if not name or not grade then return false end

  local allowedGrades = whitelist[name]

  if not allowedGrades then return false end

  for _, allowedGrade in ipairs(allowedGrades) do

    if allowedGrade == grade then return true end

  end

  return false

end
