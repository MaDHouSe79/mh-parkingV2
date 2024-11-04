--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData, isLoggedIn, LocalVehicles, isDeleting = {}, false, {}, false

local function GetDistance(pos1, pos2)
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
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
            if LocalVehicles[i].plate == plate then return true end
        end
    end 
    return false
end

local function DeteteParkedBlip(vehicle)
    for k, v in pairs(LocalVehicles) do
        if v.entity == vehicle then RemoveBlip(v.blip) v.blip = nil end
    end
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
    Wait(500)
    isDeleting = false
end

local function DeleteLocalVehicle(plate)
    if #LocalVehicles > 0 then
        for i = 1, #LocalVehicles do
            if LocalVehicles[i] ~= nil and LocalVehicles[i].plate ~= nil then
                if plate == LocalVehicles[i].plate then
                    if LocalVehicles[i].blip ~= nil then RemoveBlip(LocalVehicles[i].blip) end
                    table.remove(LocalVehicles, i)
                end
            end
        end
    end
end

local function DeleteNearByVehicle(location)
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(location)
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

local function CreateTargetEntityMenu(vehicle)
    if DoesEntityExist(vehicle) then
        if Config.TargetScript == "qb-target" then
            exports['qb-target']:AddTargetEntity(NetworkGetNetworkIdFromEntity(vehicle), {options = {{type = "client", event = "mh-parkingV2:client:park", icon = "fas fa-car", label = Lang:t('target.park_vehicle')}, {type = "client", event = "mh-parkingV2:client:drive", icon = "fas fa-car", label = Lang:t('target.unpark_vehicle')}}, distance = 2.5})
        elseif Config.TargetScript == "ox_target" then
            exports.ox_target:addEntity(NetworkGetNetworkIdFromEntity(vehicle), {{name = 'vehicle_parking', icon = "fas fa-parking", label = Lang:t('target.park_vehicle'), event = "mh-parkingV2:client:park", distance = 2.5},  {name = 'parmeters_parking', icon = "fas fa-parking", label = Lang:t('target.unpark_vehicle'), event = "mh-parkingV2:client:drive", distance = 2.5}})
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
                        FreezeEntityPosition(vehicle, false)
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
        local netid = NetworkGetNetworkIdFromEntity(vehicle)
        local vehicleCoords = GetEntityCoords(vehicle)
        local vehicleHeading = GetEntityHeading(vehicle)
        local plate = QBCore.Functions.GetPlate(vehicle)
        local location = vector4(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading)
        QBCore.Functions.TriggerCallback("mh-parkingV2:server:save", function(callback)
            if callback.status then
                SetEntityAsMissionEntity(vehicle, true, true)
                local parked_blip = CreateParkedBlip(Lang:t('info.parked_blip',{model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))}), vehicleCoords)
                table.insert(LocalVehicles, {entity = vehicle, plate = plate, blip = parked_blip, location = vehicleCoords})
                if not Config.DisableParkNotify then Notify(callback.message, "primary", 5000) end
            elseif callback.limit then
                Notify(callback.message, "error", 5000)
            elseif not callback.owner then
                Notify(callback.message, "error", 5000)
            end
        end, plate, location, netid)
    end
end

local function SpawnVehicles(vehicles)
    while isDeleting do Citizen.Wait(10) end
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
        for i = 1, #vehicles, 1 do
            if not IsVehicleAlreadyListed(vehicles[i].plate) then
                LoadModel(vehicles[i].model)
                DeleteLocalVehicle(vehicles[i].plate)
                local closestVehicle, closestDistance = QBCore.Functions.GetClosestVehicle(vehicles[i].location)
                if closestDistance <= 1 then DeleteEntity(closestVehicle) while DoesEntityExist(closestVehicle) do Citizen.Wait(10) end end
                local vehicle = CreateVehicle(vehicles[i].model, vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z + 0.2, vehicles[i].location.w, true, true)
                while not DoesEntityExist(vehicle) do Citizen.Wait(10) end
                local netid = NetworkGetNetworkIdFromEntity(vehicle)
                SetNetworkIdExistsOnAllMachines(netid, 1)
                NetworkSetNetworkIdDynamic(netid, 0)
                SetNetworkIdCanMigrate(netid, 0)
                local livery = -1
                if vehicles[i].mods.livery ~= nil then livery = vehicles[i].mods.livery end
                QBCore.Functions.SetVehicleProperties(vehicle, vehicles[i].mods)
                exports[Config.FuelScript]:SetFuel(vehicle, vehicles[i].fuel)
                RequestCollisionAtCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z)
                SetVehicleOnGroundProperly(vehicle)
                SetEntityAsMissionEntity(vehicle, true, true)
                SetEntityInvincible(vehicle, true)
                SetEntityHeading(vehicle, vehicles[i].location.w)
                SetVehicleLivery(vehicle, vehicles[i].mods.livery)
                SetVehicleEngineHealth(vehicle, vehicles[i].mods.engineHealth)
                SetVehicleBodyHealth(vehicle, vehicles[i].mods.bodyHealth)
                SetVehiclePetrolTankHealth(vehicle, vehicles[i].mods.tankHealth)
                SetVehRadioStation(vehicle, 'OFF')
                SetVehicleDirtLevel(vehicle, 0)
                SetVehicleDamage(vehicle, vehicles[i].engine, vehicles[i].body)
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', netid, 2)
                FreezeEntityPosition(vehicle, true)
                SetModelAsNoLongerNeeded(vehicles[i].model)
                local tmpBlip = nil
                if PlayerData.citizenid == vehicles[i].citizenid then FreezeEntityPosition(vehicle, false) tmpBlip = CreateParkedBlip(Lang:t('info.parked_blip',{model = vehicles[i].model}), vehicles[i].location) CreateTargetEntityMenu(vehicle) end
                table.insert(LocalVehicles, {entity = vehicle, plate = vehicles[i].plate, blip = tmpBlip, location = vehicles[i].location})
            end
        end
    end
end

local function MakeVehiclesVisable()
    if isLoggedIn and Config.ViewDistance and #LocalVehicles > 0 then
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

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData, isLoggedIn = QBCore.Functions.GetPlayerData(), true
    TriggerServerEvent("mh-parkingV2:server:refreshVehicles")
    TriggerServerEvent('mh-parkingV2:server:onjoin')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerData, isLoggedIn = QBCore.Functions.GetPlayerData(), true
        TriggerServerEvent("mh-parkingV2:server:refreshVehicles")
        TriggerServerEvent('mh-parkingV2:server:onjoin')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then PlayerData, isLoggedIn = {}, false end
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
    if isLoggedIn then RemoveVehicles(vehicles) Wait(1000) SpawnVehicles(vehicles) end
end)

RegisterNetEvent("mh-parkingV2:client:notify", function(message, type, length)
    if isLoggedIn then Notify(message, type, length) end
end)

RegisterNetEvent("mh-parkingV2:client:deletePlate", function(plate)
    if isLoggedIn then DeleteLocalVehicle(plate) end
end)

RegisterNetEvent("mh-parkingV2:client:park", function()
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if vehicle ~= -1 and distance ~= -1 and distance <= 5.0 then
        QBCore.Functions.TriggerCallback('mh-parkingV2:server:isVehicleParked', function(isNotParked)
            if isNotParked then BlinkVehiclelights(vehicle, 2) Wait(500) Save(vehicle) end -- 1 Open 2 Locked
        end, QBCore.Functions.GetPlate(vehicle), 0)
    else
        Notify(Lang:t('info.no_vehicle_nearby'), "error", 2000)
    end
end)

RegisterNetEvent("mh-parkingV2:client:drive", function()
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if vehicle ~= -1 and distance ~= -1 and distance <= 5.0 then
        QBCore.Functions.TriggerCallback('mh-parkingV2:server:isVehicleParked', function(isParked)
            if isParked then BlinkVehiclelights(vehicle, 1) Wait(500) Drive(vehicle) end -- 1 Open 2 Locked
        end, QBCore.Functions.GetPlate(vehicle), 3)
    else
        Notify(Lang:t('info.no_vehicle_nearby'), "error", 2000)
    end
end)

RegisterNetEvent("mh-parkingV2:client:autoPark", function(driver, netid)
    if isLoggedIn then
        local player = PlayerData.source
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then if player == driver then Save(vehicle) else TaskLeaveVehicle(player, vehicle, 1) end end
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
    while true do Wait(2000) MakeVehiclesVisable() end
end)

CreateThread(function()
    while true do Wait(3000) CheckDistanceToForceGrounded() end
end)
