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
        ['get_in_vehicle'] = "Get In Vehicle",
        ['select_vehicle'] = "Select Vehicle",
        ["owner"] = "Owner: ~y~%{owner}~s~",
        ["plate"] = "Plate: ~g~%{plate}~s~",
        ["model"] = "Model: ~b~%{model}~s~",
        ["brand"] = "Brand: ~o~%{brand}~s~",
        ['playeraddasvip'] = "You have been added as vip for the park system",
        ['isaddedasvip'] = "Player has been added as vip for the park system",
        ['playerremovedasvip'] = "Player has been removed as vip for the park system",
        ['steet'] = "Staat: %{steet}",
        ['fuel'] = "Brandstof: %{fuel}",
        ['engine'] = "Motor: %{engine}",
        ['body'] = "Body: %{body}",
        ['click_to_set_waypoint'] = "Click to set waypoint",
        ['close'] = "Close",
        ['park_menu'] = "Parked Menu",
        ['press_to_attach'] = "Press E to attach the boat to trailer",
        ['unable_to_park'] = "Unable to park",
        ['parking_lot'] = "Parking Lot",
    },
    commands = {
        ['addvip'] = "Parking Add VIP",
        ['addvip_info'] = "The id of the player you want to add",
        ['addvip_info_amount'] = "Max park amount",
        ['removevip'] = "Parking Remove Vip",
        ['removevip_info'] = "The id of the player you want to remove",
    }
}
--Lang:t('info.parking_lot')
Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})