local Translations = {
    info = {
        ['not_the_owner'] = "You don't own this vehicle...",
        ['remove_vehicle_zone'] = "Vehicle removed from the parking zone.",
        ['limit_parking'] = "You gave reached the parking limit Limit(%{limit}).",
        ['vehicle_parked'] = "Vehicle is packed.",
        ['already_parked'] = "Vehicle is already parked.",
        ['parked_blip'] = "Parked: %{model}",
        ['no_vehicle_nearby'] = "No vehicle nearby.",
    },
    target = {
        ['park_vehicle'] = "Park Vehicle",
        ['unpark_vehicle'] = "Unpark Vehicle",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
