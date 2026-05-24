function Notify(src, text, type)
    TriggerClientEvent('ox_lib:notify', src, {
        title = L("bodyguards"),
        description = text,
        type = type
    })
end