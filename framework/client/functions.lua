LocalVehicles = {} 
diableParkedBlips = {}
isDeleting = false
isInVehicle = false
isEnteringVehicle = false
currentVehicle = 0
currentSeat = 0
parkMenu = nil
displayOwnerText = Config.UseVehicleOwnerText
Parking = {}
Parking.Functions = {}

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
    if PlayerData.citizenid == data.citizenid then blip = Parking.Functions.CreateParkedBlip(Lang:t('info.parked_blip',{model = GetDisplayNameFromVehicleModel(GetEntityModel(data.entity))}), data.location) end
    table.insert(LocalVehicles, {citizenid = data.citizenid, fullname = data.fullname, plate = data.plate, model = data.model, blip = blip, location = data.location, entity = entity or nil})
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
        if v.entity == vehicle then RemoveBlip(v.blip) v.blip = nil end
    end
end

function Parking.Functions.BlinkVehiclelights(vehicle, state)
    SetVehicleLights(vehicle, 2) Wait(150) SetVehicleLights(vehicle, 0) Wait(150) SetVehicleLights(vehicle, 2) Wait(150) SetVehicleLights(vehicle, 0)
    TriggerServerEvent('mh-parkingV2:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), state)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.2)
end

function Parking.Functions.SetVehicleDamage(vehicle, engine, body)
    local engine = engine + 0.0
    local body = body + 0.0
    if body < 900.0 then for i = 0, 7, 1 do SmashVehicleWindow(vehicle, i) end end
    if body < 800.0 then for i = 1, 6, 1 do SetVehicleDoorBroken(vehicle, i, true) end end
    if engine < 700.0 then for i = 0, 7, 1 do SetVehicleTyreBurst(vehicle, i, false, 990.0) end end
    if engine < 500.0 then for i = 0, 7, 1 do SetVehicleTyreBurst(vehicle, i, true, 1000.0) end end
    SetVehicleEngineHealth(vehicle, engine)
    SetVehicleBodyHealth(vehicle, body)
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
                    if LocalVehicles[i].blip ~= nil then RemoveBlip(LocalVehicles[i].blip) end
                    table.remove(LocalVehicles, i)
                end
            end
        end
    end
end

function Parking.Functions.DeleteNearByVehicle(location)
    local vehicle, distance = GetClosestVehicle(location)
    if distance <= 1 then
        for i = 1, #LocalVehicles do
            if LocalVehicles[i].entity == vehicle then table.remove(LocalVehicles, i) end
            local tmpModel = GetEntityModel(vehicle)
            SetModelAsNoLongerNeeded(tmpModel)
            DeleteEntity(vehicle)
            tmpModel = nil
        end
    end
end

function Parking.Functions.CreateTargetEntityMenu(vehicle)
    if DoesEntityExist(vehicle) then
        local netid = NetworkGetNetworkIdFromEntity(vehicle)
        if Config.TargetScript == "qb-target" then
            exports['qb-target']:AddTargetEntity(netid, {
                options = {
                    {
                        type = "client",
                        event = "mh-parkingV2:client:park",
                        icon = "fas fa-car",
                        label = Lang:t('target.park_vehicle'),
                        canInteract = function(entity, distance, data)
                            local isParked = IsVehicleAlreadyListed(GetVehicleNumberPlateText(entity))
                            if isParked then return false end
                            return true
                        end
                    }, {
                        type = "client",
                        event = "mh-parkingV2:client:drive",
                        icon = "fas fa-car",
                        label = Lang:t('target.unpark_vehicle'),
                        canInteract = function(entity, distance, data)
                            local isParked = IsVehicleAlreadyListed(GetVehicleNumberPlateText(entity))
                            if not isParked then return false end
                            return true
                        end
                    }
                }, 
                distance = 2.5
            })
        elseif Config.TargetScript == "ox_target" then
            exports.ox_target:addEntity(netid, {
                {
                    icon = "fas fa-parking",
                    label = Lang:t('target.park_vehicle'),
                    event = "mh-parkingV2:client:park",
                    canInteract = function(entity, distance, coords, name)
                        local isParked = IsVehicleAlreadyListed(GetVehicleNumberPlateText(entity))
                        if isParked then return false end
                        return true
                    end,
                    distance = 2.5
                }, {
                    icon = "fas fa-parking",
                    label = Lang:t('target.unpark_vehicle'),
                    event = "mh-parkingV2:client:drive",
                    canInteract = function(entity, distance, coords, name)
                        local isParked = IsVehicleAlreadyListed(GetVehicleNumberPlateText(entity))
                        if not isParked then return false end
                        return true
                    end,
                    distance = 2.5
                }
            })
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
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
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
	-- create a blip in the middle
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
        local plate = GetVehicleNumberPlateText(vehicle)
        local netid = NetworkGetNetworkIdFromEntity(vehicle)
        while not IsPedInAnyVehicle(PlayerPedId(), false) do Wait(100) end
        TriggerCallback("mh-parkingV2:server:drive", function(callback)
            if callback.status then
                SetEntityAsMissionEntity(vehicle, true, true)
                Parking.Functions.DeteteParkedBlip(vehicle)
                TriggerCallback("mh-parkingV2:server:getVehicleData", function(vehicleData)
                    if type(vehicleData) == 'table' then
                        Parking.Functions.DeleteLocalVehicle(plate)
                        SetEntityInvincible(vehicle, false)
                        FreezeEntityPosition(vehicle, false)
                        SetVehiclePetrolTankHealth(vehicle, 1000.0)
                        TriggerServerEvent('mh-parkingV2:server:setVehLockState', netid, 1)
                        if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                    elseif type(vehicleData) == 'boolean' then
                        Notify(callback.message, "error", 5000)
                    end
                end, plate)
            end
        end, plate, netid)
    end    
end

function Parking.Functions.Save(vehicle)
    local allowToPark = Parking.Functions.AllowToPark(GetEntityCoords(PlayerPedId()))
    if allowToPark then
        if DoesEntityExist(vehicle) then
            local netid = NetworkGetNetworkIdFromEntity(vehicle)
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local plate = GetVehicleNumberPlateText(vehicle)
            local vehicleCoords = GetEntityCoords(vehicle)
            local vehicleHeading = GetEntityHeading(vehicle)
            local location = vector4(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading)
            while IsPedInAnyVehicle(PlayerPedId(), false) do Wait(100) end
            TriggerCallback("mh-parkingV2:server:save", function(callback)
                if callback.status then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    Parking.Functions.CreateTargetEntityMenu(vehicle)
                    if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                    SetVehicleDoorsShut(vehicle, false)
                    Wait(2000)
                    FreezeEntityPosition(vehicle, true)
                elseif callback.limit then
                    Notify(callback.message, "error", 5000)
                elseif not callback.owner then
                    Notify(callback.message, "error", 5000)
                end
            end, plate, location, netid, model)
        end        
    end
end

function Parking.Functions.SpawnVehicles(vehicles)
    while isDeleting do Citizen.Wait(1000) end
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
        for i = 1, #vehicles, 1 do
            if not Parking.Functions.IsVehicleAlreadyListed(vehicles[i].plate) then
                local livery = -1
                LoadModel(vehicles[i].model)
                Parking.Functions.DeleteLocalVehicle(vehicles[i].plate)
                local closestVehicle, closestDistance = GetClosestVehicle(vehicles[i].location)
                if closestDistance <= 0.5 then DeleteEntity(closestVehicle) while DoesEntityExist(closestVehicle) do Citizen.Wait(10) end end
                local vehicle = CreateVehicle(vehicles[i].model, vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z + 0.2, vehicles[i].location.w, true)
                while not DoesEntityExist(vehicle) do Citizen.Wait(500) end  
                NetworkFadeInEntity(vehicle, false, true)
                while NetworkIsEntityFading(vehicle) do Wait(0) end
                SetEntityAsMissionEntity(vehicle, true, true)
                if vehicles[i].mods.livery ~= nil then livery = vehicles[i].mods.livery end
                SetVehicleProperties(vehicle, vehicles[i].mods)
                RequestCollisionAtCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z)
                SetVehicleOnGroundProperly(vehicle)
                SetModelAsNoLongerNeeded(vehicles[i].model)
                SetEntityInvincible(vehicle, true)
                SetEntityHeading(vehicle, vehicles[i].location.w)
                SetVehicleLivery(vehicle, vehicles[i].mods.livery)
                SetVehicleEngineHealth(vehicle, vehicles[i].mods.engineHealth)
                SetVehicleBodyHealth(vehicle, vehicles[i].mods.bodyHealth)
                SetVehiclePetrolTankHealth(vehicle, vehicles[i].mods.tankHealth)
                SetVehRadioStation(vehicle, 'OFF')
                SetVehicleDirtLevel(vehicle, 0)
                SetVehicleDamage(vehicle, vehicles[i].engine, vehicles[i].body)
                TriggerServerEvent('mh-parkingV2:server:setVehLockState', VehToNet(vehicle), 2)
                SetVehicleDoorsLocked(vehicle, 2)
                exports["LegacyFuel"]:SetFuel(vehicle, vehicles[i].fuel)
                Parking.Functions.AddParkedVehicle(vehicle, vehicles[i])
                Wait(1000)
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
        Notify(Lang:t('info.no_waipoint', {distance = Round(distance, 2)}), "error", 5000)
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
            local model = GetEntityModel(vehicle)
            local name = GetDisplayNameFromVehicleModel(model)
            local netId = VehToNet(vehicle)
            isEnteringVehicle = true
            TriggerServerEvent('mh-parkingV2:server:enteringVehicle', vehicle, seat, name, netId)
        elseif not DoesEntityExist(GetVehiclePedIsTryingToEnter(ped)) and not IsPedInAnyVehicle(ped, true) and isEnteringVehicle then
            isEnteringVehicle = false
        elseif IsPedInAnyVehicle(ped, false) then
            isEnteringVehicle = false
            isInVehicle = true
            currentVehicle = GetVehiclePedIsUsing(ped)
            currentSeat = GetPedVehicleSeat(ped)
            local model = GetEntityModel(currentVehicle)
            local name = GetDisplayNameFromVehicleModel(model)
            local netId = VehToNet(currentVehicle)
            TriggerServerEvent('mh-parkingV2:server:enteredVehicle', currentVehicle, currentSeat, name, netId)
        end
    elseif isInVehicle then
        if not IsPedInAnyVehicle(ped, false) or IsPlayerDead(PlayerId()) then
            local model = GetEntityModel(currentVehicle)
            local name = GetDisplayNameFromVehicleModel(model)
            local netId = VehToNet(currentVehicle)
            TriggerServerEvent('mh-parkingV2:server:leftVehicle', currentVehicle, currentSeat, name, netId)
            isInVehicle = false
            currentVehicle = 0
            currentSeat = 0
        end
    end
end

function Parking.Functions.DisplayOwnerText()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for k, vehicle in pairs(LocalVehicles) do
        local owner, model, brand, plate = vehicle.fullname, "", "", ""
        for k, v in pairs(Config.Vehicles) do
            if v.model == vehicle.model then
                model, brand, plate = v.name, v.brand, v.plate
            end
        end
        if GetDistance(playerCoords, vehicle.location) < Config.VehicleOwnerTextDisplayDistance then
            if model ~= nil and brand ~= nil and owner ~= nil then
                local owner = Lang:t("info.owner", {owner = owner})
                local model = Lang:t("info.model", {model = model})
                local brand = Lang:t("info.brand", {brand = brand})
                local plate = Lang:t("info.plate", {plate = vehicle.plate})
                Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z, model .. '\n' .. brand .. '\n' .. plate .. '\n' .. owner, 0, 0.04, 0.04)
            end
        end
    end
end

function Parking.Functions.TargetPark()
    local vehicle, distance = Parking.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if vehicle ~= -1 and distance ~= -1 and distance <= 5.0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerCallback('mh-parkingV2:server:isVehicleParked', function(isNotParked)
            if not isNotParked then 
                Parking.Functions.BlinkVehiclelights(vehicle, 2) -- 1 Open 2 Locked
                Wait(500) 
                Parking.Functions.Save(vehicle) 
            end 
        end, plate, 0)
    else
        Notify(Lang:t('info.no_vehicle_nearby'), "error", 2000)
    end    
end

function Parking.Functions.TargetDrive()
    local vehicle, distance = GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if vehicle ~= -1 and distance ~= -1 and distance <= 5.0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerCallback('mh-parkingV2:server:isVehicleParked', function(isParked)
            if isParked then 
                Parking.Functions.BlinkVehiclelights(vehicle, 1)  -- 1 Open 2 Locked
                Wait(500) 
                Parking.Functions.Drive(vehicle) 
            end
        end, plate, 3)
    else
        Notify(Lang:t('info.no_vehicle_nearby'), "error", 2000)
    end    
end

function Parking.Functions.AutoPark(driver, netid)
    if isLoggedIn then
        local player = GetPlayerServerId(PlayerId())
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then if player == driver then Parking.Functions.Save(vehicle) elseif player ~= driver then TaskLeaveVehicle(player, vehicle, 1) end end
    end
end

function Parking.Functions.autoDrive(driver, netid)
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
                    title = v.vehicle:upper().." "..v.plate.." is parked",
                    description = "Steet: "..v.street.."\nFuel: "..v.fuel.."\nEngine: "..v.engine.."\nBody: "..v.body.."\nClick to set waypoint",
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