--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData, isLoggedIn, LocalVehicles, isDeleting = {}, false, {}, false
local diableParkedBlips = {}
local isInVehicle = false
local isEnteringVehicle = false
local currentVehicle = 0
local currentSeat = 0
local parkMenu = nil
local displayOwnerText = Config.UseVehicleOwnerText

local function GetDistance(pos1, pos2)
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
end

local function GetCurrentStreetName(coords)
    return GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
end

local function Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

local function SamePlates(plate1, plate2)
    plate1 = Trim(plate1)
    plate2 = Trim(plate2)
    return (plate1 == plate2)
end

local function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(50)
    end
end

local function IsVehicleAlreadyListed(plate)
    if #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            if SamePlates(LocalVehicles[i].plate, plate) then return true end
        end
    end 
    return false
end

local function DeteteParkedBlip(vehicle)
    for k, v in pairs(LocalVehicles) do
        if v.entity == vehicle then RemoveBlip(v.blip) v.blip = nil end
    end
end

local function DeleteAllDisableParkedBlips()
    for k, blip in pairs(diableParkedBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    diableParkedBlips = {}
end

local function CreateBlipCircle(coords, text, radius, color, sprite)
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
	SetBlipScale(blip, 0.6)
	SetBlipColour(blip, color)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandSetBlipName(blip)
    diableParkedBlips[#diableParkedBlips + 1] = blip
end

local function IsCloseByStationPump(coords)
    for hash in pairs(Config.DisableNeedByPumpModels) do
        local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, hash, false, true, true)
        if pump ~= 0 then return true end
    end
    return false
end

local function IsCloseByCoords(coords)
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

local function IsCloseByParkingLot(coords)
    for k, v in pairs(Config.AllowedParkingLots) do
        if GetDistance(coords, v.coords) < v.radius then return true end
    end
    return false
end

local function AllowToPark(coords)
    local isAllowd = false
    if Config.UseParkingLotsOnly then 
        if IsCloseByParkingLot(coords) and not IsCloseByStationPump(coords) then isAllowd = true end
    elseif not Config.UseParkingLotsOnly then 
        if not IsCloseByCoords(coords) and not IsCloseByStationPump(coords) then isAllowd = true end
    end
    return isAllowd
end

local function BlinkVehiclelights(vehicle, state)
    SetVehicleLights(vehicle, 2) Wait(150) SetVehicleLights(vehicle, 0) Wait(150) SetVehicleLights(vehicle, 2) Wait(150) SetVehicleLights(vehicle, 0)
    TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), state)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.2)
end

local function CreateParkedBlip(label, location)
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

local function SetVehicleDamage(vehicle, engine, body)
    local engine = engine + 0.0
    local body = body + 0.0
    if body < 900.0 then for i = 0, 7, 1 do SmashVehicleWindow(vehicle, i) end end
    if body < 800.0 then for i = 1, 6, 1 do SetVehicleDoorBroken(vehicle, i, true) end end
    if engine < 700.0 then for i = 0, 7, 1 do SetVehicleTyreBurst(vehicle, i, false, 990.0) end end
    if engine < 500.0 then for i = 0, 7, 1 do SetVehicleTyreBurst(vehicle, i, true, 1000.0) end end
    SetVehicleEngineHealth(vehicle, engine)
    SetVehicleBodyHealth(vehicle, body)
end

local function Notify(message, type, length)
    local exist = true
    if Config.NotifyScript == "ox_lib" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        lib.notify({title = "MH Parking V2", description = message, type = type})
    elseif Config.NotifyScript == "k5_notify" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        exports["k5_notify"]:notify("MH Parking V2", message, "k5style", length)
    elseif Config.NotifyScript == "okokNotify" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        exports['okokNotify']:Alert("MH Parking V2", message, length, type)
    elseif Config.NotifyScript == "Roda_Notifications" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        exports['Roda_Notifications']:showNotify("MH Parking V2", message, type, length)
    elseif Config.NotifyScript == "qb" then
        QBCore.Functions.Notify({text = "MH Parking V2", caption = message}, type, length)
    else
        QBCore.Functions.Notify({text = "MH Parking V2", caption = message}, type, length)
    end
end

local function Draw3DText(x, y, z, textInput, fontId, scaleX, scaleY)
    local p = GetGameplayCamCoords()
    local dist = #(p - vector3(x, y, z))
    local scale = (1 / dist) * 20
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    SetTextScale(scaleX * scale, scaleY * scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(250, 250, 250, 255)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x, y, z + 2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function AddParkedVehicle(entity, data)
    local blip = nil
    if PlayerData.citizenid == data.citizenid then  
        blip = CreateParkedBlip(Lang:t('info.parked_blip',{model = GetDisplayNameFromVehicleModel(GetEntityModel(data.entity))}), data.location)
    end
    table.insert(LocalVehicles, {citizenid = data.citizenid, fullname = data.fullname, plate = data.plate, model = data.model, blip = blip, location = data.location, entity = entity or nil})
end

local function RemoveVehicles(vehicles)
    isDeleting = true
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] ~= nil then
        for i = 1, #vehicles, 1 do
            local vehicle, distance = QBCore.Functions.GetClosestVehicle(vehicles[i].location)
            if NetworkGetEntityIsLocal(vehicle) and distance < 1 then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if not DoesEntityExist(driver) or not IsPedAPlayer(driver) then
                    local tmpModel = GetEntityModel(vehicle)
                    SetModelAsNoLongerNeeded(tmpModel)
                    DeteteParkedBlip(vehicle)
                    DeleteEntity(vehicle)
                end
            end
        end
    end
    LocalVehicles = {}
    Wait(1000)
    isDeleting = false
end

local function DeleteLocalVehicle(plate)
    if #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            if LocalVehicles[i] ~= nil and LocalVehicles[i].plate ~= nil then
                if SamePlates(plate, LocalVehicles[i].plate) then
                    if LocalVehicles[i].blip ~= nil then RemoveBlip(LocalVehicles[i].blip) end
                    table.remove(LocalVehicles, i)
                end
            end
        end
    end
end

local function Drive(vehicle)
    if DoesEntityExist(vehicle) then
        local plate = QBCore.Functions.GetPlate(vehicle)
        local netid = NetworkGetNetworkIdFromEntity(vehicle)
        QBCore.Functions.TriggerCallback("mh-parkingV2:server:drive", function(callback)
            if callback.status then
                SetEntityAsMissionEntity(vehicle, true, true)
                DeteteParkedBlip(vehicle)
                QBCore.Functions.TriggerCallback("mh-parkingV2:server:getVehicleData", function(vehicleData)
                    if type(vehicleData) == 'table' then
                        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', netid, 1)
                        DeleteLocalVehicle(plate)
                        SetEntityInvincible(vehicle, false)
                        if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                    elseif type(vehicleData) == 'boolean' then
                        Notify(callback.message, "error", 5000)
                    end
                end, plate)
            end
        end, plate, netid)
    end
end

local function Save(vehicle)
    if DoesEntityExist(vehicle) then
        local allowToPark = AllowToPark(GetEntityCoords(PlayerPedId()))
        if allowToPark then
            local netid = NetworkGetNetworkIdFromEntity(vehicle)
            local vehicleCoords = GetEntityCoords(vehicle)
            local vehicleHeading = GetEntityHeading(vehicle)
            local plate = QBCore.Functions.GetPlate(vehicle)
            local street = GetCurrentStreetName(GetEntityCoords(PlayerPedId()))
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local location = vector4(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading)
            QBCore.Functions.TriggerCallback("mh-parkingV2:server:save", function(callback)
                if callback.status then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
                    Wait(1500)
                    local seats = GetVehicleModelNumberOfSeats(GetHashKey(model))
                    for i = 1, seats, 1 do SetVehicleDoorShut(vehicle, i, false) end -- will close all doors from 0-5
                elseif callback.limit then
                    Notify(callback.message, "error", 5000)
                elseif not callback.owner then
                    Notify(callback.message, "error", 5000)
                end
            end, plate, location, netid, model:lower(), street)
        end
    end
end

local function SpawnVehicles(vehicles)
    while isDeleting do Citizen.Wait(100) end
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
        for i = 1, #vehicles, 1 do
            if not IsVehicleAlreadyListed(vehicles[i].plate) then
                local livery = -1
                LoadModel(vehicles[i].model)
                DeleteLocalVehicle(vehicles[i].plate)
                local closestVehicle, closestDistance = QBCore.Functions.GetClosestVehicle(vehicles[i].location)
                if closestDistance <= 1 then DeleteEntity(closestVehicle) while DoesEntityExist(closestVehicle) do Citizen.Wait(10) end end
                local vehicle = CreateVehicle(vehicles[i].model, vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z + 0.2, vehicles[i].location.w, false)
                while not DoesEntityExist(vehicle) do Citizen.Wait(500) end               
                if vehicles[i].mods.livery ~= nil then livery = vehicles[i].mods.livery end
                QBCore.Functions.SetVehicleProperties(vehicle, vehicles[i].mods)
                exports[Config.FuelScript]:SetFuel(vehicle, vehicles[i].fuel)
                RequestCollisionAtCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z)
                SetVehicleOnGroundProperly(vehicle)
                SetEntityAsMissionEntity(vehicle, true, true)
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
                AddParkedVehicle(vehicle, vehicles[i])
            end
        end
    end
end

local function MakeVehiclesVisable()
    if Config.ViewDistance and #LocalVehicles > 0 then
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k, vehicle in pairs(LocalVehicles) do
            if GetDistance(playerCoords, vehicle.location) < 150 and not IsEntityVisible(vehicle.entity) then
                SetEntityVisible(vehicle.entity, true, 0)
            elseif GetDistance(playerCoords, vehicle.location) > 150 and IsEntityVisible(vehicle.entity) then
                SetEntityVisible(vehicle.entity, false, 0)
            end
        end
    end
end

local function CheckDistanceToForceGrounded()
    if Config.ForceVehicleOnGound and #LocalVehicles > 0 then
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

local function GetPedVehicleSeat(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for i= -2, GetVehicleMaxNumberOfPassengers(vehicle) do if (GetPedInVehicleSeat(vehicle, i) == ped) then return i end end
    return -2
end

local function SetVehicleWaypoit(coords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = GetDistance(playerCoords, coords)
    if distance < 200 then
        Notify(Lang:t('info.no_waipoint', {distance = Round(distance, 2)}), "error", 5000)
    elseif distance > 200 then
        SetNewWaypoint(coords.x, coords.y)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerData, isLoggedIn = QBCore.Functions.GetPlayerData(), true
        TriggerServerEvent("mh-parkingV2:server:refreshVehicles")
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then PlayerData, isLoggedIn = {}, false end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData, isLoggedIn = QBCore.Functions.GetPlayerData(), true
    TriggerServerEvent("mh-parkingV2:server:refreshVehicles")
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData, isLoggedIn = {}, false
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerData.gang = gang
end)

RegisterNetEvent("mh-parkingV2:client:refreshVehicles", function(vehicles)
    RemoveVehicles(vehicles) 
    Wait(2000) 
    SpawnVehicles(vehicles)
end)

RegisterNetEvent("mh-parkingV2:client:notify", function(message, type, length)
    Notify(message, type, length)
end)

RegisterNetEvent("mh-parkingV2:client:deletePlate", function(plate)
    DeleteLocalVehicle(plate)
end)

RegisterNetEvent("mh-parkingV2:client:addVehicle", function(data)
    AddParkedVehicle(data.entity, data)
end)

RegisterNetEvent("mh-parkingV2:client:park", function()
    if isLoggedIn then
        local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        if vehicle ~= -1 and distance ~= -1 and distance <= 5.0 then
            QBCore.Functions.TriggerCallback('mh-parkingV2:server:isVehicleParked', function(isNotParked)
                if isNotParked then BlinkVehiclelights(vehicle, 2) Wait(500) Save(vehicle) end -- 1 Open 2 Locked
            end, QBCore.Functions.GetPlate(vehicle), 0)
        else
            Notify(Lang:t('info.no_vehicle_nearby'), "error", 2000)
        end
    end
end)

RegisterNetEvent("mh-parkingV2:client:drive", function()
    if isLoggedIn then
        local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        if vehicle ~= -1 and distance ~= -1 and distance <= 5.0 then
            QBCore.Functions.TriggerCallback('mh-parkingV2:server:isVehicleParked', function(isParked)
                if isParked then BlinkVehiclelights(vehicle, 1) Wait(500) Drive(vehicle) end -- 1 Open 2 Locked
            end, QBCore.Functions.GetPlate(vehicle), 3)
        else
            Notify(Lang:t('info.no_vehicle_nearby'), "error", 2000)
        end
    end
end)

RegisterNetEvent("mh-parkingV2:client:autoPark", function(driver, netid)
    if isLoggedIn then
        local player = PlayerData.source
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then if player == driver then Save(vehicle) elseif player ~= driver then TaskLeaveVehicle(player, vehicle, 1) end end
    end
end)

RegisterNetEvent("mh-parkingV2:client:autoDrive", function(driver, netid)
    if isLoggedIn then
        local player = PlayerData.source
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) and player == driver then Drive(vehicle) end
    end
end)

CreateThread(function()
    while true do Wait(2000) if isLoggedIn then MakeVehiclesVisable() end end
end)

CreateThread(function()
    while true do Wait(3000) if isLoggedIn then CheckDistanceToForceGrounded() end end
end)

CreateThread(function()
    if Config.UseParkingLotsOnly then
        for k, zone in pairs(Config.AllowedParkingLots) do
            if Config.UseParkingLotsBlips then
                CreateBlipCircle(zone.coords, "Parking Lot", zone.radius, zone.color, zone.sprite)
            end
        end
    end
    if Config.UseUnableParkingBlips then
        for k, zone in pairs(Config.NoParkingLocations) do
	    CreateBlipCircle(zone.coords, "Unable to park", zone.radius, zone.color, zone.sprite)
        end
    end
end)

CreateThread(function()
	while true do
	Wait(0)
        if isLoggedIn then
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
                    TriggerServerEvent('mh-parkingV2:server:enteringAborted')
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
	Wait(50)
    end
end)

RegisterNetEvent('mh-parkingV2:client:GetVehicleMenu', function()
    if isLoggedIn then
        QBCore.Functions.TriggerCallback("mh-parkingV2:server:GetVehicles", function(vehicles)
            if #vehicles >= 1 then
                local options = {}
                for k, v in pairs(vehicles) do
                    local coords = json.decode(v.location)
                    options[#options + 1] = {title = v.vehicle:upper().." "..v.plate.." is parked", description = "Steet: "..v.street.."\nFuel: "..v.fuel.."\nEngine: "..v.engine.."\nBody: "..v.body.."\nClick to set waypoint", arrow = false, onSelect = function() SetVehicleWaypoit(coords) end}
                end
                options[#options + 1] = {title = "Close", icon = "fa-solid fa-stop", description = '', arrow = false, onSelect = function() end}
                lib.registerContext({id = 'parkMenu', title = "MH Parking V2", icon = "fa-solid fa-warehouse", options = options})
                lib.showContext('parkMenu')
            else
                Notify(Lang:t('info.no_vehicles_parked'), "error", 5000)
            end
        end)
    end
end)

RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function()
    if parkMenu ~= nil then
        exports['qb-radialmenu']:RemoveOption(parkMenu)
        parkMenu = nil
    end
    parkMenu = exports['qb-radialmenu']:AddOption({id = 'park_vehicle', title = 'Parked Menu', icon = "square-parking", type = 'client', event = "mh-parkingV2:client:GetVehicleMenu", shouldClose = true}, parkMenu)
end)

RegisterCommand('toggleparktext', function()
    displayOwnerText = not displayOwnerText
end, false)

CreateThread(function()
    while true do
        if displayOwnerText then
            local playerCoords = GetEntityCoords(PlayerPedId())
            for k, v in pairs(LocalVehicles) do
                if GetDistance(playerCoords, v.location) < Config.VehicleOwnerTextDisplayDistance then
                    if v.fullname ~= nil and v.model ~= nil and v.plate ~= nil then
                        if (QBCore.Shared.Vehicles[v.model] ~= nil) then
                            local owner = Lang:t("info.owner", {owner = v.fullname})
                            local model = Lang:t("info.model", {model = QBCore.Shared.Vehicles[v.model].name})
                            local brand = Lang:t("info.brand", {brand = QBCore.Shared.Vehicles[v.model].brand})
                            local plate = Lang:t("info.plate", {plate = v.plate})
                            Draw3DText(v.location.x, v.location.y, v.location.z, model .. '\n' .. brand .. '\n' .. plate .. '\n' .. owner, 0, 0.04, 0.04)
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)
