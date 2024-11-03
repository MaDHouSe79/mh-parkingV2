local Translations = {
    info = {
        ['not_the_owner'] = "Je bent niet de eigenaar van dit voertuig...",
        ['remove_vehicle_zone'] = "Voertuig verwijderd uit de parkeerzone",
        ['limit_parking'] = "U heeft de parkeerlimiet bereikt. Limiet((%limit))",
        ['vehicle_parked'] = "Voertuig staat geparkeerd",
        ['already_parked'] = "Voertuig staat al geparkeerd",
        ['parked_blip'] = "Geparkeerd: {%model}",
        ['no_vehicle_nearby'] = "Geen voertuig in de buurt",
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