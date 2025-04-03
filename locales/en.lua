local Translations = {
    info = {
        ['not_the_owner'] = "You don't own this vehicle...",
        ['remove_vehicle_zone'] = "Vehicle removed from the parking zone.",
        ['limit_parking'] = "You have reached the parking limit Limit(%{limit}).",
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
        ["brand"] = "Brand: ~o~%{brand}~s~",
        ['playeraddasvip'] = "You have been added as vip for the park system",
        ['isaddedasvip'] = "Player has been added as vip for the park system",
        ['playerremovedasvip'] = "Player has been removed as vip for the park system",
    },
    commands = {
        ['addvip'] = "Parking Add VIP",
        ['addvip_info'] = "The id of the player you want to add",
        ['addvip_info_amount'] = "Max park amount",
        ['removevip'] = "Parking Remove Vip",
        ['removevip_info'] = "The id of the player you want to remove",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})