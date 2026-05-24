lib.addCommand("migratev2", {

  help = "Run the V2 migration script for dealership data",

  restricted = "group.admin"

}, function(src)

  if src ~= 0 and not Framework.Server.IsAdmin(src) then

    return

  end

  Migrate.Server.RunV2Migration()

end)

lib.addCommand(Config.DealerAdminCommand or "dealeradmin", {

  help = "Open the dealer admin panel",

  restricted = false

}, function(src)

  if not Framework.Server.IsAdmin(src) then

    Framework.Server.Notify(src, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. src .. " tried to access the dealer admin panel without permission", "warning")

    return

  end

  TriggerClientEvent("jg-dealerships:client:open-admin", src)

end)

lib.addCommand(Config.MyFinanceCommand or "myfinance", {

  help = "View and manage your financed vehicles",

  restricted = false

}, function(src)

  lib.callback.await("jg-dealerships:client:open-finance-menu", src)

end)

lib.addCommand(Config.DirectSaleCommand or "directsale", {

  help = "Open the direct sale tablet (must be in a dealership)",

  restricted = false

}, function(src)

  lib.callback.await("jg-dealerships:client:open-direct-sale-tablet", src)

end)

lib.addCommand("ctm", {

  help = "Cancel the current trucking mission",

  restricted = false

}, function(src)

  lib.callback.await("jg-dealerships:client:cancel-trucking-mission", src)

end)
