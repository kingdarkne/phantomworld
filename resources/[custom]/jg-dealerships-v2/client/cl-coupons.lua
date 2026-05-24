RegisterNUICallback("get-coupons", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-coupons", false, data))

end)

RegisterNUICallback("create-coupon", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:create-coupon", false, data))

end)

RegisterNUICallback("update-coupon", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:update-coupon", false, data))

end)

RegisterNUICallback("delete-coupon", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:delete-coupon", false, data))

end)

RegisterNUICallback("generate-coupon-code", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:generate-coupon-code", false, data))

end)

RegisterNUICallback("validate-coupon", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:validate-coupon", false, data))

end)
