local Translations = {
    info = {
        ['not_the_owner'] = "Je bent niet de eigenaar van dit voertuig...",
        ['remove_vehicle_zone'] = "Voertuig verwijderd uit de parkeerzone",
        ['limit_parking'] = "U heeft de parkeerlimiet bereikt. Limiet(%{limit})",
        ['vehicle_parked'] = "Voertuig staat geparkeerd",
        ['already_parked'] = "Voertuig staat al geparkeerd",
        ['parked_blip'] = "Geparkeerd: %{model}",
        ['no_vehicle_nearby'] = "Geen voertuig in de buurt",
        ['no_waipoint'] = "Serieus heb je voor deze %{distance} meter een waypoint nodig?",
        ['no_vehicles_parked'] = "Je hebt geen voertuigen gepakeerd staan.",
        ["stop_car"] = "Stop het voertuig...",
        ["owner"] = "Eigenaar: ~y~%{owner}~s~",
        ["plate"] = "Kenteken: ~g~%{plate}~s~",
        ["model"] = "Model: ~b~%{model}~s~",
        ["brand"] = "Brand ~o~%{brand}~s~",
    },
    target = {
        ['park_vehicle'] = "Park Voertuig",
        ['unpark_vehicle'] = "Unpark Voertuig",
    },
    commands = {
        ['addvip'] = "Parking VIP Toevoegen",
        ['addvip_info'] = "De id can de player die je wilt toevoegen",
        ['addvip_info_amount'] = "Max park totaal",
        ['removevip'] = "Parking Vip Verwijderen",
        ['removevip_info'] = "De ID van de player dat je wilt verwijderen",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
