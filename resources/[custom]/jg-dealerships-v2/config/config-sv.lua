-- ================================================
-- Server-side custom callbacks
-- ================================================
-- Customize server behaviour: logs, finance paid off, repossession, etc.

-- [After vehicle purchase (server)]
-- Args:
--   vehNetId      = vehicle network id
--   plate         = plate
--   purchaseType  = "personal" or "society"
--   amount        = amount paid
--   paymentMethod = "cash" or "bank"
--   financed      = financed (true/false)
RegisterNetEvent("jg-dealerships:server:purchase-vehicle:config", function(vehNetId, plate, purchaseType, amount, paymentMethod, financed)

  local src = source

  local vehicle = NetworkGetEntityFromNetworkId(vehNetId)

  -- Add server logic (DB logs, Discord, etc.)

end)

-- [Finance fully paid off]
-- Args:
--   playerId = server id
--   plate    = plate that was paid off
RegisterNetEvent("jg-dealerships:server:vehicle-finance-complete", function(playerId, plate)
  -- Add logic after loan is cleared

end)

-- [Finance default / vehicle repossessed]
-- Args:
--   playerId   = server id
--   plate      = repossessed plate
--   amountOwed = amount still owed
RegisterNetEvent("jg-dealerships:server:vehicle-finance-defaulted", function(playerId, plate, amountOwed)
  -- Add logic after repossession

end)

-- [Sell vehicle pre-check]
-- Return true to allow sell, false to block.
-- Args:
--   dealershipId = dealership id
--   plate        = plate
--   model        = model name (e.g. "adder")
--   price        = offer amount
function SellVehiclePreCheck(dealershipId, plate, model, price)
  -- Add custom checks
  return true

end

-- [Purchase pre-check]
-- Return true to allow purchase, false to block.
-- Args:
--   playerId         = buyer server id
--   dealershipId     = dealership id
--   plate            = generated plate
--   model            = model name
--   purchaseType     = "personal" or "society"
--   amountToPay      = amount
--   paymentMethod    = payment method
--   society          = society name (nil if personal)
--   societyType      = society type
--   financed         = financed
--   noOfPayments     = number of payments
--   downPayment      = down payment amount
--   isDirectSale     = staff direct sale
--   sellerPlayerId   = seller id if direct sale
-- Minimum rank required to buy super class vehicles (luxury dealership)
local SUPER_RANK_REQUIRED = 50

-- GTA:V super class vehicle models (add custom super cars to this table)
local SUPER_CLASS_MODELS = {
  adder=true, entityxf=true, zentorno=true, turismor=true, osiris=true,
  t20=true, fmj=true, pfister811=true, vagner=true, deveste8=true,
  emerus=true, s80r=true, krieger=true, thrax=true, vigilante=true,
  x80proto=true, cheetah=true, cheetah2=true, infernus=true, bullet=true,
  voltic=true, voltic2=true, shotaro=true, cyclone=true, tempesta=true,
  visione=true, xa21=true, tyrant=true, tezeract=true, pariah=true,
  sc1=true, banshee2=true, le7b=true, reaper=true, nero=true, nero2=true,
  prototipo=true, sultanrs=true, comet3=true, comet4=true, comet5=true,
  autarch=true, ignus=true, imorgon=true, torero2=true, entity2=true,
  entity3=true, gbcity=true,
}

-- Calculate player level from XP (mirrors XNLRankBar formula)
local RockstarRanks = {
  400,1050,1900,3050,4750,6250,8000,9900,12000,14250,16700,19350,22100,25100,28200,31500,
  34950,38550,42350,46250,50350,54600,59000,63550,68250,73100,78100,83250,88550,94000,
  99600,105350,111200,117250,123400,129700,136150,142750,149500,156350,163400,170500,
  177800,185250,192800,200500,208300,216300,224400,232600,241000,249500,258150,266900,
  275800,284800,294000,303250,312700,322250,331900,341700,351650,361700,371900,382250,
  392700,403250,413950,424800,435750,446800,458000,469350,480800,492350,504050,515900,
  527850,539900,552100,564400,576850,589400,602100,614900,627800,640850,654050,667300,
  680700,694250,707900,721650,735550,749550,763650,777900,792175
}
local function getLevelFromXP(xp)
  xp = tonumber(xp) or 0
  for i = 1, #RockstarRanks do
    if xp < RockstarRanks[i] then return i end
  end
  local base = RockstarRanks[#RockstarRanks]
  local lvl = #RockstarRanks
  local step = 14325
  while xp >= base + step do
    base = base + step
    step = step + 25
    lvl = lvl + 1
  end
  return lvl + 1
end

function PurchaseVehiclePreCheck(playerId, dealershipId, plate, model, purchaseType, amountToPay, paymentMethod, society, societyType, financed, noOfPayments, downPayment, isDirectSale, sellerPlayerId)
  -- Block super class vehicles for players below rank 50
  if SUPER_CLASS_MODELS[tostring(model):lower()] then
    local player = GetResourceState('qbx_core') == 'started' and exports.qbx_core:GetPlayer(playerId) or nil
    local citizenid = player and player.PlayerData and player.PlayerData.citizenid
    if citizenid then
      local result = exports.oxmysql:executeSync('SELECT driving FROM experience WHERE cid = ?', { citizenid })
      local xp = (result and result[1] and tonumber(result[1].driving)) or 0
      local level = getLevelFromXP(xp)
      if level < SUPER_RANK_REQUIRED then
        TriggerClientEvent('ox_lib:notify', playerId, {
          type = 'error',
          title = 'Rank Required',
          description = ('Super class vehicles require Rank %d. Your rank: %d'):format(SUPER_RANK_REQUIRED, level),
          duration = 6000
        })
        return false
      end
    end
  end
  return true
end
