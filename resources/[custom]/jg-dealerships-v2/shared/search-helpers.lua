SearchHelpers = SearchHelpers or {}

local MONTH_NAMES = {

  ["january"] = 1, ["jan"] = 1,

  ["february"] = 2, ["feb"] = 2,

  ["march"] = 3, ["mar"] = 3,

  ["april"] = 4, ["apr"] = 4,

  ["may"] = 5,

  ["june"] = 6, ["jun"] = 6,

  ["july"] = 7, ["jul"] = 7,

  ["august"] = 8, ["aug"] = 8,

  ["september"] = 9, ["sep"] = 9, ["sept"] = 9,

  ["october"] = 10, ["oct"] = 10,

  ["november"] = 11, ["nov"] = 11,

  ["december"] = 12, ["dec"] = 12

}

local function parseMonthName(searchTerm)

  local lower = searchTerm:lower()

  return MONTH_NAMES[lower]

end

local function parseYear(searchTerm)

  local year = tonumber(searchTerm)

  if year and year >= 1900 and year <= 2100 then

    return year

  end

  return nil

end

function SearchHelpers.BuildDateCondition(searchTerm, dateColumn)

  if not searchTerm or searchTerm == "" then return nil, nil end

  local trimmed = Trim(searchTerm)

  local lower = trimmed:lower()

  local conditions = {}

  local params = {}

  local year = parseYear(trimmed)

  if year then

    conditions[#conditions+1] = ("YEAR(%s) = ?"):format(dateColumn)

    params[#params+1] = year

    return conditions[1], params

  end

  local month = parseMonthName(trimmed)

  if month then

    conditions[#conditions+1] = ("MONTH(%s) = ?"):format(dateColumn)

    params[#params+1] = month

    return conditions[1], params

  end

  local monthYearMatch = trimmed:match("^(%a+)%s+(%d+)$")

  if monthYearMatch then

    local monthPart, yearPart = trimmed:match("^(%a+)%s+(%d+)$")

    local parsedMonth = parseMonthName(monthPart)

    local parsedYear = parseYear(yearPart)

    if parsedMonth and parsedYear then

      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)

      params[#params+1] = parsedMonth

      params[#params+1] = parsedYear

      return conditions[1], params

    end

  end

  local yearMonthMatch = trimmed:match("^(%d+)%s+(%a+)$")

  if yearMonthMatch then

    local yearPart, monthPart = trimmed:match("^(%d+)%s+(%a+)$")

    local parsedMonth = parseMonthName(monthPart)

    local parsedYear = parseYear(yearPart)

    if parsedMonth and parsedYear then

      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)

      params[#params+1] = parsedMonth

      params[#params+1] = parsedYear

      return conditions[1], params

    end

  end

  local yearDashMonth = trimmed:match("^(%d%d%d%d)%-(%d%d?)$")

  if yearDashMonth then

    local y, m = trimmed:match("^(%d%d%d%d)%-(%d%d?)$")

    local parsedYear = tonumber(y)

    local parsedMonth = tonumber(m)

    if parsedYear and parsedMonth and parsedMonth >= 1 and parsedMonth <= 12 then

      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)

      params[#params+1] = parsedMonth

      params[#params+1] = parsedYear

      return conditions[1], params

    end

  end

  local monthSlashYear = trimmed:match("^(%d%d?)[/%-](%d%d%d%d)$")

  if monthSlashYear then

    local m, y = trimmed:match("^(%d%d?)[/%-](%d%d%d%d)$")

    local parsedMonth = tonumber(m)

    local parsedYear = tonumber(y)

    if parsedYear and parsedMonth and parsedMonth >= 1 and parsedMonth <= 12 then

      conditions[#conditions+1] = ("(MONTH(%s) = ? AND YEAR(%s) = ?)"):format(dateColumn, dateColumn)

      params[#params+1] = parsedMonth

      params[#params+1] = parsedYear

      return conditions[1], params

    end

  end

  local ymdMatch = trimmed:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")

  if ymdMatch then

    local y, m, d = trimmed:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")

    conditions[#conditions+1] = ("DATE(%s) = ?"):format(dateColumn)

    params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(y), tonumber(m), tonumber(d))

    return conditions[1], params

  end

  local dateSlashMatch = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d%d%d)$")

  if dateSlashMatch then

    local first, second, year = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d%d%d)$")

    local firstNum, secondNum = tonumber(first), tonumber(second)

    local day, month

    if firstNum > 12 then

      day, month = firstNum, secondNum

    elseif secondNum > 12 then

      month, day = firstNum, secondNum

    else

      conditions[#conditions+1] = ("(DATE(%s) = ? OR DATE(%s) = ?)"):format(dateColumn, dateColumn)

      params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(year), secondNum, firstNum)
      params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(year), firstNum, secondNum)
      return conditions[1], params

    end

    conditions[#conditions+1] = ("DATE(%s) = ?"):format(dateColumn)

    params[#params+1] = ("%04d-%02d-%02d"):format(tonumber(year), month, day)

    return conditions[1], params

  end

  local dateSlashShortYear = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d)$")

  if dateSlashShortYear then

    local first, second, shortYear = trimmed:match("^(%d%d?)/(%d%d?)/(%d%d)$")

    local firstNum, secondNum = tonumber(first), tonumber(second)

    local fullYear = 2000 + tonumber(shortYear)

    local day, month

    if firstNum > 12 then

      day, month = firstNum, secondNum

    elseif secondNum > 12 then

      month, day = firstNum, secondNum

    else

      conditions[#conditions+1] = ("(DATE(%s) = ? OR DATE(%s) = ?)"):format(dateColumn, dateColumn)

      params[#params+1] = ("%04d-%02d-%02d"):format(fullYear, secondNum, firstNum)
      params[#params+1] = ("%04d-%02d-%02d"):format(fullYear, firstNum, secondNum)
      return conditions[1], params

    end

    conditions[#conditions+1] = ("DATE(%s) = ?"):format(dateColumn)

    params[#params+1] = ("%04d-%02d-%02d"):format(fullYear, month, day)

    return conditions[1], params

  end

  return nil, nil

end

function SearchHelpers.BuildSearchConditions(searchTerm, textColumns, dateColumn, concatenatedColumns)

  if not searchTerm or searchTerm == "" then

    return "", {}

  end

  local trimmed = Trim(searchTerm)

  local conditions = {}

  local params = {}

  local likePattern = "%" .. trimmed:lower() .. "%"

  for _, col in ipairs(textColumns) do

    conditions[#conditions+1] = ("LOWER(%s) LIKE ?"):format(col)

    params[#params+1] = likePattern

  end

  if concatenatedColumns then

    for _, colGroup in ipairs(concatenatedColumns) do

      if #colGroup > 1 then

        local concatParts = {}

        for _, col in ipairs(colGroup) do

          concatParts[#concatParts+1] = col

        end

        local concatExpr = "CONCAT_WS(' ', " .. table.concat(concatParts, ", ") .. ")"

        conditions[#conditions+1] = ("LOWER(%s) LIKE ?"):format(concatExpr)

        params[#params+1] = likePattern

      end

    end

  end

  if dateColumn then

    local dateCondition, dateParams = SearchHelpers.BuildDateCondition(trimmed, dateColumn)

    if dateCondition and dateParams then

      conditions[#conditions+1] = dateCondition

      for _, p in ipairs(dateParams) do

        params[#params+1] = p

      end

    end

  end

  if #conditions == 0 then

    return "", {}

  end

  return "(" .. table.concat(conditions, " OR ") .. ")", params

end
