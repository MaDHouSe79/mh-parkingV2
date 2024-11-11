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
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
