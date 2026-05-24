# Client API - Job and PAP

Use these exports instead of calling internal `next_housing:job:*` or `next_housing:pap:*` events directly.

## Job Endpoints

### `exports['next_housing']:JobRequestHouses(cb)`
Fire refresh request (event-backed).

```lua
cb(success, reason) -- reason: "requested"
```

### `exports['next_housing']:JobGetHouses(cb)`
Direct callback endpoint for houses list.

```lua
cb(houses)
```

### `exports['next_housing']:JobGetHouseImages(houseId, cb)`
Direct callback endpoint for one house images.

```lua
cb(result) -- server payload (success/images/message)
```

### `exports['next_housing']:JobCreateContract(data, cb)`
### `exports['next_housing']:JobUpdateContract(data, cb)`
### `exports['next_housing']:JobCancelContract(contractId, houseId, cb)`
### `exports['next_housing']:JobUpdateHousePrice(data, cb)`
### `exports['next_housing']:JobBuyHouseForAgency(houseId, paymentMethod, cb)`
Dedicated action endpoints (event-backed).

```lua
cb(success, reason) -- reason: "requested"
```

### `exports['next_housing']:JobSignContract(contractId, cb)`
### `exports['next_housing']:JobDeclineContract(contractId, cb)`
Dedicated callback endpoints.

```lua
cb(result) -- server payload
```

## PAP Endpoints

### `exports['next_housing']:PapRequestData(cb)`
### `exports['next_housing']:PapRequestListings(cb)`
### `exports['next_housing']:PapRequestMyListings(cb)`
### `exports['next_housing']:PapRequestContracts(cb)`
Dedicated refresh endpoints (event-backed).

```lua
cb(success, reason) -- reason: "requested"
```

### `exports['next_housing']:PapGetPropertyDetails(propertyId, cb)`
### `exports['next_housing']:PapGetContractData(offerId, cb)`
### `exports['next_housing']:PapGetMessages(offerId, cb)`
Dedicated callback endpoints.

```lua
cb(result)
```

### `exports['next_housing']:PapUpdatePropertyName(propertyId, newName, cb)`
### `exports['next_housing']:PapSignContract(contractId, cb)`
### `exports['next_housing']:PapDeclineContract(contractId, cb)`
### `exports['next_housing']:PapTerminateContract(data, cb)`
Dedicated callback action endpoints.

```lua
cb(result)
```

### `exports['next_housing']:PapCreateListing(data, cb)`
### `exports['next_housing']:PapDeleteListing(listingId, cb)`
### `exports['next_housing']:PapMakeOffer(data, cb)`
### `exports['next_housing']:PapAcceptOffer(offerId, cb)`
### `exports['next_housing']:PapDeclineOffer(offerId, cb)`
### `exports['next_housing']:PapCancelOffer(offerId, cb)`
### `exports['next_housing']:PapSendMessage(offerId, content, cb)`
Dedicated action endpoints (event-backed).

```lua
cb(success, reason) -- reason: "requested"
```

## Example

```lua
RegisterCommand("nh_job_houses", function()
    exports["next_housing"]:JobGetHouses(function(houses)
        print(("job houses count=%s"):format(type(houses) == "table" and #houses or 0))
    end)
end)

RegisterCommand("nh_pap_contract", function(_, args)
    local listingId = tonumber(args[1])
    exports["next_housing"]:PapSignContract(listingId, function(result)
        print(("pap sign success=%s message=%s"):format(
            tostring(result and result.success),
            tostring(result and result.message)
        ))
    end)
end)
```
