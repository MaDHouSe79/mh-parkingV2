Parking = {}
Parking.Functions = {}
displayOwnerText = Config.UseVehicleOwnerText
local LocalVehicles = {}
local diableParkedBlips = {}
local isDeleting = false
local isInVehicle = false
local isEnteringVehicle = false
local currentVehicle = 0
local currentSeat = 0
local parkMenu = nil
local disableControll = false

function Parking.Functions.CreateParkedBlip(label, location)
    if Config.UseParkedBlips then
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 545)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(blip)
        return blip
    else
        return nil
    end
end

function Parking.Functions.AddParkedVehicle(entity, data)
    local blip = nil
    if PlayerData.citizenid == data.citizenid then blip = Parking.Functions.CreateParkedBlip(Lang:t('info.parked_blip', { model = GetDisplayNameFromVehicleModel(GetEntityModel(data.entity)) }), data.location) end
    LocalVehicles[#LocalVehicles + 1] = {citizenid = data.citizenid, fullname = data.fullname, plate = data.plate, model = data.model, blip = blip, location = data.location, entity = entity or nil, fuel = data.fuel, body = data.body, engine = data.engine}
end

function Parking.Functions.GetPedVehicleSeat(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for i = -2, GetVehicleMaxNumberOfPassengers(vehicle) do
        if (GetPedInVehicleSeat(vehicle, i) == ped) then return i end
    end
    return -2
end

function Parking.Functions.IsVehicleAlreadyListed(plate)
    if #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            if SamePlates(LocalVehicles[i].plate, plate) then return true end
        end
    end
    return false
end

function Parking.Functions.DeteteParkedBlip(vehicle)
    for k, v in pairs(LocalVehicles) do
        if v.entity == vehicle then
            RemoveBlip(v.blip)
            v.blip = nil
        end
    end
end

function Parking.Functions.BlinkVehiclelights(vehicle, state)
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
    Wait(1000)
    if state then
        FreezeEntityPosition(vehicle, true)
        SetEntityInvincible(vehicle, true)
    else
        FreezeEntityPosition(vehicle, false)
        SetEntityInvincible(vehicle, false)
    end
    disableControll = false
end

function Parking.Functions.RemoveVehicles(vehicles)
    isDeleting = true
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] ~= nil then
        for i = 1, #vehicles, 1 do
            local vehicle, distance = GetClosestVehicle(vehicles[i].location)
            if NetworkGetEntityIsLocal(vehicle) and distance < 1 then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if not DoesEntityExist(driver) or not IsPedAPlayer(driver) then
                    local tmpModel = GetEntityModel(vehicle)
                    SetModelAsNoLongerNeeded(tmpModel)
                    Parking.Functions.DeteteParkedBlip(vehicle)
                    NetworkFadeOutEntity(vehicle, false, true)
                    while NetworkIsEntityFading(vehicle) do Wait(0) end
                    Wait(100)
                    DeleteEntity(vehicle)
                end
            end
        end
    end
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

function Parking.Functions.DeleteNearByVehicle(location)
    local vehicle, distance = GetClosestVehicle(location)
    if distance <= 1 then
        for i = 1, #LocalVehicles do
            if LocalVehicles[i].entity == vehicle then
                RemoveBlip(LocalVehicles[i].blip)
                LocalVehicles[i] = nil
            end
            local tmpModel = GetEntityModel(vehicle)
            SetModelAsNoLongerNeeded(tmpModel)
            DeleteEntity(vehicle)
            tmpModel = nil
        end
    end
end

function Parking.Functions.IsCloseByStationPump(coords)
    for hash in pairs(Config.DisableNeedByPumpModels) do
        local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, hash, false, true, true)
        if pump ~= 0 then return true end
    end
    return false
end

function Parking.Functions.IsCloseByCoords(coords)
    for k, v in pairs(Config.NoParkingLocations) do
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
    for k, v in pairs(Config.AllowedParkingLots) do
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
    if Config.DebugBlipForRadius then
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
    if Config.UseParkingLotsOnly then
        if Parking.Functions.IsCloseByParkingLot(coords) and not Parking.Functions.IsCloseByStationPump(coords) then isAllowd = true end
    elseif not Config.UseParkingLotsOnly then
        if not Parking.Functions.IsCloseByCoords(coords) and not Parking.Functions.IsCloseByStationPump(coords) then isAllowd = true end
    end
    return isAllowd
end

function Parking.Functions.Drive(vehicle)
    if DoesEntityExist(vehicle) then
        local data = { netid = NetworkGetNetworkIdFromEntity(vehicle), plate = GetVehicleNumberPlateText(vehicle) }
        while not IsPedInAnyVehicle(PlayerPedId(), false) do Wait(100) end
        TriggerCallback("mh-parkingV2:server:Drive", function(callback)
            if callback.status then
                SetEntityAsMissionEntity(vehicle, true, true)
                Parking.Functions.DeteteParkedBlip(vehicle)
                TriggerCallback("mh-parkingV2:server:GetVehicleData", function(vehicleData)
                    if type(vehicleData) == 'table' then
                        Parking.Functions.DeleteLocalVehicle(data.plate)
                        SetEntityInvincible(vehicle, false)
                        FreezeEntityPosition(vehicle, false)
                        TriggerServerEvent('mh-parkingV2:server:SetVehLockState', netid, 1)
                        if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                    elseif type(vehicleData) == 'boolean' then
                        Notify(callback.message, "error", 5000)
                    end
                end, data.plate)
            end
        end, data)
    end
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

function Parking.Functions.Save(vehicle)
    local allowToPark = Parking.Functions.AllowToPark(GetEntityCoords(PlayerPedId()))
    if allowToPark then
        if DoesEntityExist(vehicle) then
            local canSave = true
            local vehicleCoords = GetEntityCoords(vehicle)
            local vehicleHeading = GetEntityHeading(vehicle)
            while IsPedInAnyVehicle(PlayerPedId(), false) do Wait(100) end
            if Config.OnlyAutoParkWhenEngineIsOff and GetIsVehicleEngineRunning(vehicle) then canSave = false end
            if canSave then
                TriggerServerEvent("mh-parkingV2:server:ClearAllSeats", NetworkGetNetworkIdFromEntity(vehicle))
                for i = 0, GetNumberOfVehicleDoors(vehicle), 1 do
                    while GetVehicleDoorAngleRatio(vehicle, i) > 0.0 do
                        SetVehicleDoorShut(vehicle, i, false)
                        Wait(50)
                    end
                    Wait(50)
                end
                TriggerCallback("mh-parkingV2:server:Save", function(callback)
                    if callback.status then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                        Parking.Functions.BlinkVehiclelights(vehicle, 2) -- 1 Open 2 Locked
                    elseif callback.limit then
                        Notify(callback.message, "error", 5000)
                    elseif not callback.owner then
                        Notify(callback.message, "error", 5000)
                    end
                end, {
                    netid = NetworkGetNetworkIdFromEntity(vehicle),
                    plate = GetVehicleNumberPlateText(vehicle),
                    fuel = exports[Config.FuelScript]:GetFuel(vehicle),
                    engine = GetVehicleEngineHealth(vehicle),
                    body = GetVehicleBodyHealth(vehicle),
                    street = GetStreetName(vehicle),
                    model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                    location = vector4(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading)
                })

            end
        end
    end
end

function Parking.Functions.SpawnVehicles(vehicles)
    while isDeleting do Citizen.Wait(1000) end
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
        for i = 1, #vehicles, 1 do
            if not Parking.Functions.IsVehicleAlreadyListed(vehicles[i].plate) then
                local model = GetHashKey(vehicles[i].model)
                LoadModel(model)
                Parking.Functions.DeleteLocalVehicle(vehicles[i].plate)
                local closestVehicle, closestDistance = GetClosestVehicle(vehicles[i].location)
                if closestVehicle ~= -1 and closestDistance <= 0.5 then
                    DeleteEntity(closestVehicle)
                    while DoesEntityExist(closestVehicle) do Citizen.Wait(50) end
                end
                local vehicle = CreateVehicle(model, vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z + 0.2, vehicles[i].location.w, true, true)
                while not DoesEntityExist(vehicle) do Citizen.Wait(500) end
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleProperties(vehicle, vehicles[i].mods)
                Parking.Functions.AddParkedVehicle(vehicle, vehicles[i])
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
                SetEntityInvincible(vehicle, true)
                SetVehicleEngineHealth(vehicle, vehicles[i].engine)
                SetVehicleBodyHealth(vehicle, vehicles[i].body)
                SetVehiclePetrolTankHealth(vehicle, vehicles[i].mods.tankHealth)
                SetVehRadioStation(vehicle, 'OFF')
                SetVehicleDirtLevel(vehicle, 0)
                SetVehicleDamage(vehicle, vehicles[i].engine, vehicles[i].body)
                TriggerServerEvent('mh-parkingV2:server:SetVehLockState', VehToNet(vehicle), 2)
                SetVehicleDoorsLocked(vehicle, 2)
                if GetResourceState(Config.FuelScript) ~= 'missing' then exports[Config.FuelScript]:SetFuel(vehicle, vehicles[i].fuel) end
                Wait(1500)
                FreezeEntityPosition(vehicle, true)
            end
        end
    end
end

function Parking.Functions.MakeVehiclesVisable()
    if isLoggedIn and Config.ViewDistance and #LocalVehicles > 0 then
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k, vehicle in pairs(LocalVehicles) do
            if GetDistance(playerCoords, vehicle.location) < 150 and not IsEntityVisible(vehicle.entity) then
                SetEntityVisible(vehicle.entity, true)
            elseif GetDistance(playerCoords, vehicle.location) > 150 and IsEntityVisible(vehicle.entity) then
                SetEntityVisible(vehicle.entity, false)
            end
        end
    end
end

function Parking.Functions.CheckDistanceToForceGrounded()
    if isLoggedIn and Config.ForceVehicleOnGound and #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            local playerCoords = GetEntityCoords(PlayerPedId())
            if LocalVehicles[i].entity ~= nil and DoesEntityExist(LocalVehicles[i].entity) and not LocalVehicles[i].isGrounded then
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
        if GetDistance(playerCoords, vehicle.location) < Config.VehicleOwnerTextDisplayDistance then
            local owner, plate, model, brand = vehicle.fullname, vehicle.plate, "", ""
            for k, v in pairs(Config.Vehicles) do
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
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function()
            if parkMenu ~= nil then
                exports['qb-radialmenu']:RemoveOption(parkMenu)
                parkMenu = nil
            end
            parkMenu = exports['qb-radialmenu']:AddOption({
                id = 'park_vehicle',
                title = 'Parked Menu',
                icon = "square-parking",
                type = 'client',
                event = "mh-parkingV2:client:GetVehicleMenu",
                shouldClose = true
            }, parkMenu)
        end)
    end
end

function Parking.Functions.CreateBlips()
    if Config.DebugBlipForRadius then
        for k, zone in pairs(Config.NoParkingLocations) do
            Parking.Functions.CreateBlipCircle(zone.coords, "Unable to park", zone.radius, zone.color, zone.sprite)
        end
    end
    if Config.UseParkingLotsOnly then
        for k, zone in pairs(Config.AllowedParkingLots) do
            if Config.UseParkingLotsBlips then
                Parking.Functions.CreateBlipCircle(zone.coords, "Parking Lot", zone.radius, zone.color, zone.sprite)
            end
        end
    end
end

function Parking.Functions.KeepEngineRunning()
    if IsPedInAnyVehicle(PlayerPedId(), false) and IsControlPressed(2, 75) and not IsEntityDead(PlayerPedId()) then
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
