DealershipBalance = DealershipBalance or {}

DealershipBalance.Server = DealershipBalance.Server or {}

function DealershipBalance.Server.GetBalance(dealershipId)

  local location, balance

  if Config.UseFrameworkJobs then

    location = Locations.Server.GetById(dealershipId)

    if not location or not location.job_name or location.job_name == "" then

      return nil

    end

    return Framework.Server.GetSocietyBalance(location.job_name, "job")

  else

    balance = MySQL.scalar.await(

      "SELECT balance FROM dealership_locations WHERE id = ?",

      {dealershipId}

    )

    return balance

  end

end

lib.callback.register("jg-dealerships:server:dealership-balance:get", function(source, dealershipId)

  local isEmployee = Employees.Server.IsEmployee(source, dealershipId)

  if not isEmployee then

    return false

  end

  return DealershipBalance.Server.GetBalance(dealershipId)

end)

function DealershipBalance.Server.Add(dealershipId, amount)

  local location

  if amount < 0 then

    return false, "Amount must be positive"

  end

  if Config.UseFrameworkJobs then

    location = Locations.Server.GetById(dealershipId)

    if not location or not location.job_name or location.job_name == "" then

      return false, "Dealership has no job configured"

    end

    Framework.Server.AddToSocietyFund(location.job_name, "job", amount)

  else

    MySQL.update.await(

      "UPDATE dealership_locations SET balance = balance + ? WHERE id = ?",

      {amount, dealershipId}

    )

  end

  return true

end

function DealershipBalance.Server.Remove(dealershipId, amount)

  local location

  if amount < 0 then

    return false, "Amount must be positive"

  end

  if Config.UseFrameworkJobs then

    location = Locations.Server.GetById(dealershipId)

    if not location or not location.job_name or location.job_name == "" then

      return false, "Dealership has no job configured"

    end

    Framework.Server.RemoveFromSocietyFund(location.job_name, "job", amount)

  else

    MySQL.update.await(

      "UPDATE dealership_locations SET balance = balance - ? WHERE id = ?",

      {amount, dealershipId}

    )

  end

  return true

end

function DealershipBalance.Server.HasFunds(dealershipId, amount)

  local balance = DealershipBalance.Server.GetBalance(dealershipId)

  if balance == nil then

    return false, nil

  end

  local hasFunds = amount <= balance

  return hasFunds, balance

end
