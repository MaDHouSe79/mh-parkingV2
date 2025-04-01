Parking = {}
Parking.Functions, displayOwnerText, disableControll = {}, nil, false
LocalVehicles, diableParkedBlips, currentVehicle, currentSeat = {}, {}, 0, 0
isDeleting, isInVehicle, isEnteringVehicle, parkMenu = false, false, false, nil

function Parking.Functions.OnJoin(data)
    config = data
    config.Framework = data.Framework
    displayOwnerText = data.UseVehicleOwnerText
end

function Parking.Functions.CreateParkedBlip(data)
    if config.UseParkedBlips then
        local name = config.Vehicles[GetHashKey(data.model)].name or "unknow"
        local brand = config.Vehicles[GetHashKey(data.model)].brand or "unknow"
        local blip = AddBlipForCoord(data.location.x, data.location.y, data.location.z)
        SetBlipSprite(blip, 545)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t('info.parked_blip', { model = name .." "..brand }))
        EndTextCommandSetBlipName(blip)
        return blip
    else
        return nil
    end
end

function Parking.Functions.AddParkedVehicle(entity, data)
    local blip = nil
    if PlayerData.citizenid == data.citizenid then blip = Parking.Functions.CreateParkedBlip(data) else blip = nil end
    LocalVehicles[#LocalVehicles + 1] = {
        citizenid = data.citizenid,
        fullname = data.fullname,
        plate = data.plate,
        model = data.model,
        blip = blip,
        location = data.location,
        entity = entity,
        fuel = data.fuel,
        body = data.body,
        engine = data.engine,
        steerangle = data.steerangle,
        trailerEntity = data.trailerEntity
    }
end

function Parking.Functions.DeteteParkedBlip(vehicle)
    for k, v in pairs(LocalVehicles) do
        if v.entity == vehicle then
            RemoveBlip(v.blip)
            v.blip = nil
        end
    end
end

function Parking.Functions.BlinkVehiclelights(vehicle,state)
    disableControll = true
    local ped = PlayerPedId()
    local model = 'prop_cuff_keys_01'
    LoadAnimDict('anim@mp_player_intmenu@key_fob@')
    LoadModel(model)
    local object = CreateObject(model, 0, 0, 0, true, true, true)
    while not DoesEntityExist(object) do Wait(1) end
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 57005), 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 8.0, -8.0, -1, 52, 0, false, false, false)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.2)
    SetVehicleLights(vehicle, 2)
    Wait(150)
    SetVehicleLights(vehicle, 0)
    Wait(150)
    SetVehicleLights(vehicle, 2)
    Wait(150)
    SetVehicleLights(vehicle, 0)
    TriggerServerEvent('mh-parkingV2:server:SetVehLockState', NetworkGetNetworkIdFromEntity(vehicle), state)
    SetVehicleDoorsLocked(vehicle, state)
    if IsEntityPlayingAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3) then
        DeleteObject(object)
        StopAnimTask(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 8.0)
    end
    disableControll = false
    Wait(1000)
    if state then
        FreezeEntityPosition(vehicle, true)
        SetEntityInvincible(vehicle, true)
    else
        FreezeEntityPosition(vehicle, false)
        SetEntityInvincible(vehicle, false)
    end
end

function Parking.Functions.DeleteAllTrailers()
    if type(LocalVehicles) == 'table' and #LocalVehicles > 0 then 
        for i = 1, #LocalVehicles, 1 do
            if LocalVehicles[i].trailerEntity ~= nil then
                if DoesEntityExist(LocalVehicles[i].trailerEntity) then
                    print(GetEntityModel(LocalVehicles[i].trailerEntity))
                    DeleteEntity(LocalVehicles[i].trailerEntity)
                    LocalVehicles[i].trailerEntity = nil
                end
            end
        end
    end
end

function Parking.Functions.RemoveVehicles(vehicles)
    isDeleting = true
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] ~= nil then
        for i = 1, #vehicles, 1 do
            local vehicle, distance = GetClosestVehicle(vehicles[i].location)
            if NetworkGetEntityIsLocal(vehicle) and distance < 1.0 then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if not DoesEntityExist(driver) or not IsPedAPlayer(driver) then
                    local tmpModel = GetEntityModel(vehicle)
                    SetModelAsNoLongerNeeded(tmpModel)
                    Parking.Functions.DeteteParkedBlip(vehicle)
                    NetworkFadeOutEntity(vehicle, false, true)
                    while NetworkIsEntityFading(vehicle) do Wait(0) end
                    Wait(100)
                    if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                end
            end
        end
    end
    Wait(50)
    LocalVehicles = {}
    Wait(1500)
    isDeleting = false
end

function Parking.Functions.DeleteLocalVehicle(plate)
    if #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            if LocalVehicles[i] ~= nil and LocalVehicles[i].plate ~= nil then
                if SamePlates(LocalVehicles[i].plate, plate) then
                    RemoveBlip(LocalVehicles[i].blip)
                    LocalVehicles[i] = nil
                end
            end
        end
    end
end

function Parking.Functions.IsCloseByStationPump(coords)
    for hash in pairs(config.DisableNeedByPumpModels) do
        local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, hash, false, true, true)
        if pump ~= 0 then return true end
    end
    return false
end

function Parking.Functions.IsCloseByCoords(coords)
    for k, v in pairs(config.NoParkingLocations) do
        if GetDistance(coords, v.coords) < v.radius then
            if v.job == nil then
                return true
            elseif v.job ~= nil and v.job ~= PlayerData.job.name then
                return true
            end
        end
    end
    return false
end

function Parking.Functions.IsCloseByParkingLot(coords)
    for k, v in pairs(config.AllowedParkingLots) do
        if GetDistance(coords, v.coords) < v.radius then return true end
    end
    return false
end

function Parking.Functions.DeleteAllDisableParkedBlips()
    for k, blip in pairs(diableParkedBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    diableParkedBlips = {}
end

function Parking.Functions.CreateBlipCircle(coords, text, radius, color, sprite)
    local blip = nil
    if config.DebugBlipForRadius then
        blip = AddBlipForRadius(coords, radius)
        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, color)
        SetBlipAlpha(blip, 128)
    end
    blip = AddBlipForCoord(coords)
    SetBlipHighDetail(blip, true)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandSetBlipName(blip)
    diableParkedBlips[#diableParkedBlips + 1] = blip
end

function Parking.Functions.AllowToPark(coords)
    local isAllowd = false
    if config.UseParkingLotsOnly then
        if Parking.Functions.IsCloseByParkingLot(coords) and not Parking.Functions.IsCloseByStationPump(coords) then isAllowd = true end
    elseif not config.UseParkingLotsOnly then
        if not Parking.Functions.IsCloseByCoords(coords) and not Parking.Functions.IsCloseByStationPump(coords) then isAllowd = true end
    end
    return isAllowd
end

function Parking.Functions.ClearAllSeats(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if DoesEntityExist(vehicle) then
        local inVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if inVehicle == vehicle then
            TaskLeaveVehicle(PlayerPedId(), inVehicle, 1)
        end
    end
end

function Parking.Functions.Drive(vehicle)
    if DoesEntityExist(vehicle) then
        local data = { netid = NetworkGetNetworkIdFromEntity(vehicle), plate = GetVehicleNumberPlateText(vehicle) }
        while not IsPedInAnyVehicle(PlayerPedId(), false) do Wait(100) end
        TriggerCallback("mh-parkingV2:server:Drive", function(callback)
            if callback.status then
                local hasTrailer, trailer = GetVehicleTrailerVehicle(vehicle)
                if hasTrailer then FreezeEntityPosition(trailer, false) end
                SetEntityAsMissionEntity(vehicle, true, true)
                Parking.Functions.DeteteParkedBlip(vehicle)
                TriggerCallback("mh-parkingV2:server:GetVehicleData", function(vehicleData)
                    if type(vehicleData) == 'table' then
                        Parking.Functions.DeleteLocalVehicle(data.plate)
                        SetEntityInvincible(vehicle, false)
                        FreezeEntityPosition(vehicle, false)
                        TriggerServerEvent('mh-parkingV2:server:SetVehLockState', netid, 1)
                        if not config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                    elseif type(vehicleData) == 'boolean' then
                        Notify(callback.message, "error", 5000)
                    end
                end, data.plate)
            end
        end, data)
    end
end

function Parking.Functions.Save(vehicle)
    local allowToPark = Parking.Functions.AllowToPark(GetEntityCoords(PlayerPedId()))
    if allowToPark then
        if DoesEntityExist(vehicle) then
            local canSave = true
            local vehicleCoords = GetEntityCoords(vehicle)
            local vehicleHeading = GetEntityHeading(vehicle)
            local trailerdata = nil
            local hasTrailer, trailer = GetVehicleTrailerVehicle(vehicle)
            if hasTrailer then
                local hashkey = GetEntityModel(trailer)
                local trailerProps = GetVehicleProperties(trailer)
                if config.Trailers[hashkey] then
                    trailerdata = {hash = hashkey, coords = GetEntityCoords(trailer), heading = GetEntityHeading(trailer), mods = trailerProps}
                end
            end
            while IsPedInAnyVehicle(PlayerPedId(), false) do Wait(100) end
            if config.OnlyAutoParkWhenEngineIsOff and GetIsVehicleEngineRunning(vehicle) then canSave = false end
            if canSave then
                SetEntityAsMissionEntity(vehicle, true, true)
                TriggerServerEvent("mh-parkingV2:server:ClearAllSeats", NetworkGetNetworkIdFromEntity(vehicle))
                Wait(50)
                for i = 0, GetNumberOfVehicleDoors(vehicle), 1 do
                    while GetVehicleDoorAngleRatio(vehicle, i) > 0.0 do
                        SetVehicleDoorShut(vehicle, i, false)
                        Wait(50)
                    end
                    Wait(50)
                end
                TriggerCallback("mh-parkingV2:server:Save", function(callback)
                    if callback.status then
                        Parking.Functions.BlinkVehiclelights(vehicle, 2) -- 1 Open 2 Locked
                        Notify(callback.message, "primary", 5000)
                    elseif callback.limit then
                        disableControll = false
                        Notify(callback.message, "error", 5000)
                    elseif not callback.owner then
                        disableControll = false
                        Notify(callback.message, "error", 5000)
                    end
                end, {
                    netid = NetworkGetNetworkIdFromEntity(vehicle),
                    plate = GetVehicleNumberPlateText(vehicle),
                    fuel = exports[config.FuelScript]:GetFuel(vehicle),
                    engine = GetVehicleEngineHealth(vehicle),
                    body = GetVehicleBodyHealth(vehicle),
                    street = GetStreetName(vehicle),
                    model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                    location = vector4(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading),
                    steerangle = GetVehicleSteeringAngle(vehicle),
                    trailerdata = trailerdata
                })
            else
                disableControll = false
            end
        else
            disableControll = false
        end
    else
        disableControll = false
    end
end

function CreateTrailerTarget(trailer)
    local netid = NetworkGetNetworkIdFromEntity(trailer)
    if GetResourceState("qb-target") ~= 'missing' then
        exports['qb-target']:AddTargetEntity(netid, {
            options = {{
                type = "client",
                icon = 'fas fa-skull-crossbones',
                label = "Park",
                action = function(entity)
                end,
                canInteract = function(entity, distance, data)
                    return true
                end
            }},
            distance = 5.0
        })
    elseif GetResourceState("ox_target") ~= 'missing' then
        exports.ox_target:addEntity(netid, {
            options = {
                icon = 'fas fa-skull-crossbones',
                label = "Unpark",
                onSelect = function(data)
                end,
                canInteract = function(data)
                    return true
                end,
                distance = 5.0
            },
        })
    end
end

function Parking.Functions.SpawnTrailer(vehicle, data)
    local offset, posX, posY = -5.0, 0.0, 0.0
    local heading = GetEntityHeading(vehicle)
    local vehicleCoords = GetEntityCoords(vehicle)
    if config.Trailers[data.trailerdata.hash] then
        if config.Trailers[data.trailerdata.hash].offset ~= nil then
            offset = config.Trailers[data.trailerdata.hash].offset.backwards
            if config.Trailers[data.trailerdata.hash].offset.heading ~= nil then
                heading -= config.Trailers[data.trailerdata.hash].offset.heading
                posX -= config.Trailers[data.trailerdata.hash].offset.posX
                posY -= config.Trailers[data.trailerdata.hash].offset.posY
            end
        end
    end
    local trailerSpawnPos = GetOffsetFromEntityInWorldCoords(vehicle, posX, offset, 0.5)
    local closestVehicle, closestDistance = GetClosestVehicle(trailerSpawnPos)
    if closestVehicle ~= -1 and closestDistance <= 1.5 then
        DeleteEntity(closestVehicle)
        while DoesEntityExist(closestVehicle) do
            DeleteEntity(closestVehicle)
            Wait(50)
        end
    end
    Wait(500)
    LoadModel(data.trailerdata.hash)
    local trailer = CreateVehicle(data.trailerdata.hash, trailerSpawnPos.x, trailerSpawnPos.y, vehicleCoords.z, heading, true, true)
    while not DoesEntityExist(trailer) do Wait(500) end
    SetEntityAsMissionEntity(trailer, true, true)
    SetTrailerLegsRaised(trailer)
    SetVehicleProperties(trailer, data.trailerdata.mods)
    local netid = VehToNet(trailer)
    SetNetworkIdExistsOnAllMachines(netid, true)
    NetworkSetNetworkIdDynamic(netid, false)
    SetNetworkIdCanMigrate(netid, true)
    NetworkFadeInEntity(entity, true)
    while NetworkIsEntityFading(entity) do Citizen.Wait(50) end
    SetVehicleOnGroundProperly(trailer)
    SetVehicleDirtLevel(trailer, 0)
    CreateTrailerTarget(trailer)
    Wait(1500)
    if not IsEntityPositionFrozen(trailer) then FreezeEntityPosition(trailer, true) end
    if not IsEntityPositionFrozen(vehicle) then FreezeEntityPosition(vehicle, true) end
    return trailer
end

function Parking.Functions.SpawnVehicles(vehicles)
    while isDeleting do Citizen.Wait(1000) end
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
        for i = 1, #vehicles, 1 do
            local isListed, listedVehicle = DoesVehicleAlreadyExsist(vehicles[i].plate)
            if not isListed and listedVehicle == -1 then
                local model = GetHashKey(vehicles[i].model)
                LoadModel(model)
                Parking.Functions.DeleteLocalVehicle(vehicles[i].plate)
                local closestVehicle, closestDistance = GetClosestVehicle(vehicles[i].location)
                if closestVehicle ~= -1 and closestDistance <= 5.0 then
                    while DoesEntityExist(closestVehicle) do
                        DeleteEntity(closestVehicle)
                        Wait(50)
                    end
                end
                Wait(500)
                local vehicle = CreateVehicle(model, vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z, vehicles[i].location.w, true, true)
                while not DoesEntityExist(vehicle) do Citizen.Wait(500) end
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleProperties(vehicle, vehicles[i].mods)
                SetModelAsNoLongerNeeded(model)
                local netid = VehToNet(vehicle)
                SetNetworkIdExistsOnAllMachines(netid, true)
                NetworkSetNetworkIdDynamic(netid, false)
                SetNetworkIdCanMigrate(netid, true)
                NetworkFadeInEntity(vehicle, true)
                while NetworkIsEntityFading(vehicle) do Citizen.Wait(50) end
                RequestCollisionAtCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z)
                SetEntityHeading(vehicle, vehicles[i].location.w)
                local retval, groundZ = GetGroundZFor_3dCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z, false)
                if retval then SetEntityCoords(vehicle, vehicles[i].location.x, vehicles[i].location.y, groundZ) end
                SetVehicleOnGroundProperly(vehicle)
                SetVehicleSteeringAngle(vehicle, vehicles[i].steerangle + 0.0)
                SetEntityInvincible(vehicle, true)
                SetVehRadioStation(vehicle, 'OFF')
                SetVehicleDirtLevel(vehicle, 0)
                SetVehicleDamage(vehicle, vehicles[i].engine, vehicles[i].body)
                TriggerServerEvent('mh-parkingV2:server:SetVehLockState', VehToNet(vehicle), 2)
                SetVehicleDoorsLocked(vehicle, 2)
                if GetResourceState(config.FuelScript) ~= 'missing' then exports[config.FuelScript]:SetFuel(vehicle, vehicles[i].fuel) end
                if vehicles[i].trailerdata ~= nil then
                    vehicles[i].trailerEntity = Parking.Functions.SpawnTrailer(vehicle, vehicles[i])
                else
                    if not IsEntityPositionFrozen(vehicle) then FreezeEntityPosition(vehicle, true) end
                end
                Wait(50)
                Parking.Functions.AddParkedVehicle(vehicle, vehicles[i])
            elseif isListed and listedVehicle ~= -1 then
                Parking.Functions.AddParkedVehicle(listedVehicle, vehicles[i])
            end
        end
    end
end

function Parking.Functions.MakeVehiclesVisable()
    if isLoggedIn and config.ViewDistance and #LocalVehicles > 0 then
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k, vehicle in pairs(LocalVehicles) do
            if GetDistance(playerCoords, vehicle.location) < 150 and not IsEntityVisible(vehicle.entity) then
                SetEntityVisible(vehicle.entity, true)
                if vehicle.trailerEntity ~= nil then SetEntityVisible(vehicle.trailerEntity, true) end
            elseif GetDistance(playerCoords, vehicle.location) > 150 and IsEntityVisible(vehicle.entity) then
                SetEntityVisible(vehicle.entity, false)
                if vehicle.trailerEntity ~= nil then SetEntityVisible(vehicle.trailerEntity, false) end
            end
        end
    end
end

function Parking.Functions.CheckDistanceToForceGrounded()
    if isLoggedIn and config.ForceVehicleOnGound and #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            local playerCoords = GetEntityCoords(PlayerPedId())
            if type(LocalVehicles[i]) == 'table' and LocalVehicles[i].entity ~= nil and DoesEntityExist(LocalVehicles[i].entity) and not LocalVehicles[i].isGrounded then
                if GetVehicleWheelSuspensionCompression(LocalVehicles[i].entity) == 0 or GetDistance(playerCoords, LocalVehicles[i].location) < 150 then
                    SetEntityCoords(LocalVehicles[i].entity, LocalVehicles[i].location.x, LocalVehicles[i].location.y, LocalVehicles[i].location.z)
                    SetVehicleOnGroundProperly(LocalVehicles[i].entity)
                    LocalVehicles[i].isGrounded = true
                end
            end
        end
    end
end

function Parking.Functions.SetVehicleWaypoit(coords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = GetDistance(playerCoords, coords)
    if distance < 200 then
        Notify(Lang:t('info.no_waipoint', { distance = Round(distance, 2) }), "error", 5000)
    elseif distance > 200 then
        SetNewWaypoint(coords.x, coords.y)
    end
end

function Parking.Functions.GetInAndOutVehicle()
    local ped = PlayerPedId()
    if not isInVehicle and not IsPlayerDead(PlayerId()) then
        if DoesEntityExist(GetVehiclePedIsTryingToEnter(ped)) and not isEnteringVehicle then
            local vehicle = GetVehiclePedIsTryingToEnter(ped)
            local seat = GetSeatPedIsTryingToEnter(ped)
            local name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local netId = VehToNet(vehicle)
            isEnteringVehicle = true
            TriggerServerEvent('mh-parkingV2:server:EnteringVehicle', vehicle, seat, name, netId)
        elseif not DoesEntityExist(GetVehiclePedIsTryingToEnter(ped)) and not IsPedInAnyVehicle(ped, true) and isEnteringVehicle then
            isEnteringVehicle = false
        elseif IsPedInAnyVehicle(ped, false) then
            isEnteringVehicle = false
            isInVehicle = true
            currentVehicle = GetVehiclePedIsUsing(ped)
            currentSeat = GetPedVehicleSeat(ped)
            local name = GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle))
            local netId = VehToNet(currentVehicle)
            TriggerServerEvent('mh-parkingV2:server:EnteredVehicle', currentVehicle, currentSeat, name, netId)
        end
    elseif isInVehicle then
        if not IsPedInAnyVehicle(ped, false) or IsPlayerDead(PlayerId()) then
            local name = GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle))
            local netId = VehToNet(currentVehicle)
            TriggerServerEvent('mh-parkingV2:server:LeftVehicle', currentVehicle, currentSeat, name, netId)
            isInVehicle = false
            currentVehicle = 0
            currentSeat = 0
        end
    end
end

function Parking.Functions.DisplayOwnerText()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for k, vehicle in pairs(LocalVehicles) do
        if GetDistance(playerCoords, vehicle.location) < config.VehicleOwnerTextDisplayDistance then
            local owner, plate, model, brand = vehicle.fullname, vehicle.plate, "", ""
            for k, v in pairs(config.Vehicles) do
                if v.model:lower() == vehicle.model:lower() then
                    model, brand = v.name, v.brand
                    break
                end
            end
            if model ~= nil and brand ~= nil then
                local owner = Lang:t("info.owner", { owner = vehicle.fullname })
                local model = Lang:t("info.model", { model = model })
                local brand = Lang:t("info.brand", { brand = brand })
                local plate = Lang:t("info.plate", { plate = vehicle.plate })
                Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z, model .. '\n' .. brand .. '\n' .. plate .. '\n' .. owner, 0, 0.04, 0.04)
            end
        end
    end
end

function Parking.Functions.AutoPark(driver, netid)
    if isLoggedIn then
        local player = GetPlayerServerId(PlayerId())
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then
            if player == driver then
                disableControll = true
                Parking.Functions.Save(vehicle)
            elseif player ~= driver then
                TaskLeaveVehicle(player, vehicle, 1)
            end
        end
    end
end

function Parking.Functions.AutoDrive(driver, netid)
    if isLoggedIn then
        local player = GetPlayerServerId(PlayerId())
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) and player == driver then Parking.Functions.Drive(vehicle) end
    end
end

function Parking.Functions.GetVehicleMenu()
    TriggerCallback("mh-parkingV2:server:GetVehicles", function(vehicles)
        if #vehicles >= 1 then
            local options = {}
            for k, v in pairs(vehicles) do
                local coords = json.decode(v.location)
                options[#options + 1] = {
                    title = v.vehicle:upper() .. " " .. v.plate .. " is parked",
                    description = "Steet: " .. v.street .. "\nFuel: " .. v.fuel .. "\nEngine: " .. v.engine .. "\nBody: " .. v.body .. "\nClick to set waypoint",
                    arrow = false,
                    onSelect = function()
                        Parking.Functions.SetVehicleWaypoit(coords)
                    end
                }
            end
            options[#options + 1] = {
                title = "Close",
                icon = "fa-solid fa-stop",
                description = '',
                arrow = false,
                onSelect = function()
                end
            }
            lib.registerContext({id = 'parkMenu', title = "MH Parking V2", icon = "fa-solid fa-warehouse", options = options})
            lib.showContext('parkMenu')
        else
            Notify(Lang:t('info.no_vehicles_parked'), "error", 5000)
        end
    end)
end

function Parking.Functions.RadialMenu()
    if config.Framework == 'qb' or config.Framework == 'qbx' then
        RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function()
            if parkMenu ~= nil then
                exports['qb-radialmenu']:RemoveOption(parkMenu)
                parkMenu = nil
            end
            parkMenu = exports['qb-radialmenu']:AddOption({
                id = 'park_vehicles_menu',
                title = 'Parked Menu',
                icon = "square-parking",
                type = 'client',
                event = "mh-parkingV2:client:GetVehicleMenu",
                shouldClose = true
            }, parkMenu)
        end)
    elseif config.Framework == 'esx' then
        lib.addRadialItem({
            {
                id = 'park_vehicles_menu',
                label = 'Parked Menu',
                icon = 'square-parking',
                onSelect = function()
                    TriggerEvent("mh-parkingV2:client:GetVehicleMenu")
                end
            }
        })
    end
end

function Parking.Functions.CreateBlips()
    if config.DebugBlipForRadius then
        for k, zone in pairs(config.NoParkingLocations) do
            Parking.Functions.CreateBlipCircle(zone.coords, "Unable to park", zone.radius, zone.color, zone.sprite)
        end
    end
    if config.UseParkingLotsOnly then
        for k, zone in pairs(config.AllowedParkingLots) do
            if config.UseParkingLotsBlips then
                Parking.Functions.CreateBlipCircle(zone.coords, "Parking Lot", zone.radius, zone.color, zone.sprite)
            end
        end
    end
end

function Parking.Functions.KeepEngineRunning()
    if IsPedInAnyVehicle(PlayerPedId(), false) and IsControlPressed(2, 75) and not IsEntityDead(PlayerPedId()) then
        disableControll = false
        SetVehicleEngineOn(GetVehiclePedIsIn(PlayerPedId(), false), true, true, true)
    end
end

function Parking.Functions.DisableControll()
    if IsPauseMenuActive() then SetFrontendActive(false) end
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 0, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 288, true)
    EnableControlAction(0, 213, true)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
    EnableControlAction(0, 47, true)
end

function Parking.Functions.CheckVehicleSteeringAngle()
    local angle = 0.0
    local speed = 0.0
    while true do
        Wait(0)
        local veh = GetVehiclePedIsUsing(PlayerPedId())
        if DoesEntityExist(veh) then
            local tangle = GetVehicleSteeringAngle(veh)
            if tangle > 10.0 or tangle < -10.0 then angle = tangle end
            speed = GetEntitySpeed(veh)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
            if speed < 0.1 and DoesEntityExist(vehicle) and not GetIsTaskActive(PlayerPedId(), 151) and not GetIsVehicleEngineRunning(vehicle) then
                SetVehicleSteeringAngle(vehicle, angle)
            end
            local hasTrailer, trailer = GetVehicleTrailerVehicle(vehicle)
            if hasTrailer and IsEntityPositionFrozen(trailer) then FreezeEntityPosition(trailer, false) end
        end
    end
end
