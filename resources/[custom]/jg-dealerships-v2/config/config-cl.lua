-- ================================================
-- Client-side custom callbacks
-- ================================================
-- Customize behaviour after purchase, test drive, sell, etc.
-- Add your own code in the handlers below.

-- [After vehicle purchase]
-- Args:
--   vehicle      = vehicle entity handle
--   plate        = plate text
--   purchaseType = "personal" or "society"
--   amount       = amount paid
--   paymentMethod= "cash" or "bank"
--   financed     = financed purchase (true/false)
RegisterNetEvent("jg-dealerships:client:purchase-vehicle:config", function(vehicle, plate, purchaseType, amount, paymentMethod, financed)
  -- Give vehicle keys via qbx_vehiclekeys
  TriggerEvent("qbx_vehiclekeys:client:GiveKeys", plate)
end)

-- [After test drive starts]
-- Args:
--   vehicle = test drive entity
--   plate   = test drive plate
RegisterNetEvent("jg-dealerships:client:start-test-drive:config", function(vehicle, plate)
  -- Add logic after test drive starts

end)

-- [After selling a vehicle]
-- Args:
--   vehicle = sold vehicle entity
--   plate   = plate
RegisterNetEvent("jg-dealerships:client:sell-vehicle:config", function(vehicle, plate)
  -- Default: delete the sold vehicle
  JGDeleteVehicle(vehicle)
end)

-- [Showroom entry check]
-- Called before entering; return true to allow, false to block.
-- Args:
--   dealershipId = dealership id (database)
function ShowroomPreCheck(dealershipId)
  -- Add job/permission checks here
  -- e.g. if GetPlayerJob() ~= "police" then return false end
  return true

end
