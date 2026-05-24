Currencies = Currencies or {}

Currencies.Server = Currencies.Server or {}

local registeredCurrencies = {}

function Currencies.Server.GetAll()

  return registeredCurrencies

end

function Currencies.Server.Get(currencyId)

  return registeredCurrencies[currencyId]

end

function Currencies.Server.Register(currency)

  if not currency.id then

    error("Currency must have an 'id' field")

  end

  registeredCurrencies[currency.id] = currency

  DebugPrint(("Registered currency: %s"):format(currency.id), "debug")

end

function Currencies.Server.GetPurchaseCurrencyIds()

  local ids = {}

  for id, _ in pairs(registeredCurrencies) do

    table.insert(ids, id)

  end

  return ids

end

function Currencies.Server.GetBalance(src, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then

    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")

    return 0

  end

  return currency.fetchBalance(src)

end

function Currencies.Server.AddBalance(src, amount, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then

    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")

    return false

  end

  return currency.addBalance(src, amount)

end

function Currencies.Server.RemoveBalance(src, amount, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then

    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")

    return false

  end

  return currency.removeBalance(src, amount)

end

function Currencies.Server.GetBalanceOffline(identifier, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then

    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")

    return 0

  end

  if not currency.fetchBalanceOffline then

    DebugPrint(("Currency %s does not support offline balance fetching"):format(currencyId), "warning")

    return 0

  end

  return currency.fetchBalanceOffline(identifier)

end

function Currencies.Server.RemoveBalanceOffline(identifier, amount, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then

    DebugPrint(("Unknown currency: %s"):format(currencyId), "warning")

    return false

  end

  if not currency.removeBalanceOffline then

    DebugPrint(("Currency %s does not support offline balance removal"):format(currencyId), "warning")

    return false

  end

  return currency.removeBalanceOffline(identifier, amount)

end

function Currencies.Server.ConvertToBase(amount, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then return amount end

  if currency.flatCost then

    return 0

  end

  return amount * currency.conversionRate

end

function Currencies.Server.ConvertFromBase(baseAmount, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then return baseAmount end

  if currency.flatCost then

    return currency.flatCost

  end

  return baseAmount / currency.conversionRate

end

function Currencies.Server.FormatAmount(amount, currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then

    return tostring(amount)

  end

  return string.format(currency.format, tostring(amount))

end

function Currencies.Server.AllowsFinance(currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then return false end

  if currency.flatCost then return false end

  return currency.allowFinance == true

end

function Currencies.Server.HasFlatCost(currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then return false end

  return currency.flatCost ~= nil

end

function Currencies.Server.GetFlatCost(currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then return nil end

  return currency.flatCost

end

function Currencies.Server.SupportsOffline(currencyId)

  local currency = registeredCurrencies[currencyId]

  if not currency then return false end

  return currency.fetchBalanceOffline ~= nil and currency.removeBalanceOffline ~= nil

end

function Currencies.Server.GetAllForClient()

  local result = {}

  for id, currency in pairs(registeredCurrencies) do

    table.insert(result, {

      id = currency.id,

      label = currency.label,

      format = currency.format,

      conversionRate = currency.conversionRate,

      flatCost = currency.flatCost,

      allowFinance = currency.allowFinance,

    })

  end

  return result

end

lib.callback.register("jg-dealerships:server:get-currencies", function()

  return Currencies.Server.GetAllForClient()

end)

lib.callback.register("jg-dealerships:server:get-player-balances", function(src, currencyIds)

  local balances = {}

  for _, currencyId in ipairs(currencyIds or Currencies.Server.GetPurchaseCurrencyIds()) do

    balances[currencyId] = Currencies.Server.GetBalance(src, currencyId)

  end

  return balances

end)

exports("getCurrencies", Currencies.Server.GetAll)

exports("getCurrency", Currencies.Server.Get)

exports("registerCurrency", Currencies.Server.Register)

Currencies.Server.Register({

  id = "bank",

  label = "Bank Account",

  format = Config.Currency or "$%s",

  conversionRate = 1.0,

  allowFinance = true,

  fetchBalance = function(src)

    local player = Framework.Server.GetPlayer(src)

    if not player then return 0 end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      return player.PlayerData.money.bank or 0

    elseif Config.Framework == "ESX" then

      for _, acc in pairs(player.getAccounts()) do

        if acc.name == "bank" then

          return acc.money or 0

        end

      end

    end

    return 0

  end,

  addBalance = function(src, amount)

    local player = Framework.Server.GetPlayer(src)

    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      player.Functions.AddMoney("bank", Round(amount, 0))

    elseif Config.Framework == "ESX" then

      player.addAccountMoney("bank", Round(amount, 0))

    end

    return true

  end,

  removeBalance = function(src, amount)

    local player = Framework.Server.GetPlayer(src)

    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      player.Functions.RemoveMoney("bank", Round(amount, 0))

    elseif Config.Framework == "ESX" then

      player.removeAccountMoney("bank", Round(amount, 0))

    end

    return true

  end,

  fetchBalanceOffline = function(identifier)

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      local result = MySQL.scalar.await(

        "SELECT JSON_EXTRACT(money, '$.bank') FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?",

        { identifier }

      )

      return tonumber(result) or 0

    elseif Config.Framework == "ESX" then

      local result = MySQL.scalar.await(

        "SELECT accounts FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?",

        { identifier }

      )

      if not result then return 0 end

      local accounts = json.decode(result)

      if type(accounts) == "table" then

        if accounts.bank then

          return tonumber(accounts.bank) or 0

        else

          for _, acc in pairs(accounts) do

            if acc.name == "bank" then

              return tonumber(acc.money) or 0

            end

          end

        end

      end

    end

    return 0

  end,

  removeBalanceOffline = function(identifier, amount)

    amount = Round(amount, 0)

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      local affectedRows = MySQL.update.await(

        "UPDATE " .. Framework.PlayersTable .. " SET money = JSON_SET(money, '$.bank', JSON_EXTRACT(money, '$.bank') - ?) WHERE " .. Framework.PlayersTableId .. " = ?",

        { amount, identifier }

      )

      return affectedRows > 0

    elseif Config.Framework == "ESX" then

      local result = MySQL.single.await(

        "SELECT accounts FROM " .. Framework.PlayersTable .. " WHERE " .. Framework.PlayersTableId .. " = ?",

        { identifier }

      )

      if not result or not result.accounts then return false end

      local accounts = json.decode(result.accounts)

      if type(accounts) == "table" then

        if accounts.bank then

          accounts.bank = (tonumber(accounts.bank) or 0) - amount

        else

          for i, acc in pairs(accounts) do

            if acc.name == "bank" then

              accounts[i].money = (tonumber(acc.money) or 0) - amount

              break

            end

          end

        end

        MySQL.update.await(

          "UPDATE " .. Framework.PlayersTable .. " SET accounts = ? WHERE " .. Framework.PlayersTableId .. " = ?",

          { json.encode(accounts), identifier }

        )

        return true

      end

    end

    return false

  end,

})

Currencies.Server.Register({

  id = "cash",

  label = "Cash",

  format = Config.Currency or "$%s",

  conversionRate = 1.0,

  allowFinance = false,
  fetchBalance = function(src)

    local player = Framework.Server.GetPlayer(src)

    if not player then return 0 end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      return player.PlayerData.money.cash or 0

    elseif Config.Framework == "ESX" then

      for _, acc in pairs(player.getAccounts()) do

        if acc.name == "money" then

          return acc.money or 0

        end

      end

    end

    return 0

  end,

  addBalance = function(src, amount)

    local player = Framework.Server.GetPlayer(src)

    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      player.Functions.AddMoney("cash", Round(amount, 0))

    elseif Config.Framework == "ESX" then

      player.addAccountMoney("money", Round(amount, 0))

    end

    return true

  end,

  removeBalance = function(src, amount)

    local player = Framework.Server.GetPlayer(src)

    if not player then return false end

    if Config.Framework == "QBCore" or Config.Framework == "Qbox" then

      player.Functions.RemoveMoney("cash", Round(amount, 0))

    elseif Config.Framework == "ESX" then

      player.removeAccountMoney("money", Round(amount, 0))

    end

    return true

  end,

  fetchBalanceOffline = nil,

  removeBalanceOffline = nil,

})
