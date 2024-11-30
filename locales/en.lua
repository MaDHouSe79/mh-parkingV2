local Translations = {
    info = {
        ['not_the_owner'] = "You don't own this vehicle...",
        ['remove_vehicle_zone'] = "Vehicle removed from the parking zone.",
        ['limit_parking'] = "You gave reached the parking limit Limit(%{limit}).",
        ['vehicle_parked'] = "Vehicle is packed.",
        ['already_parked'] = "Vehicle is already parked.",
        ['parked_blip'] = "Parked: %{model}",
        ['no_vehicle_nearby'] = "No vehicle nearby.",
        ['no_waipoint'] = "Seriously do you need a waypoint for this %{distance} meters?",
        ['no_vehicles_parked'] = "You have no vehicles parked.",
        ["stop_car"] = "Stop the vehicle...",
        ["owner"] = "Owner: ~y~%{owner}~s~",
        ["plate"] = "Plate: ~g~%{plate}~s~",
        ["model"] = "Model: ~b~%{model}~s~",
        ["brand"] = "Brand ~o~%{brand}~s~",
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