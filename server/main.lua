--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()

local function AutoSave()
    if SV_Config.AutoSave then
        local players = QBCore.Functions.GetPlayers()
        for id in pairs(players) do
            local Player = QBCore.Functions.GetPlayer(id)
            if Player then
                local ped = GetPlayerPed(Player.PlayerData.source)
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local vehicleHeading = GetEntityHeading(vehicle)
                    local location = vector4(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleHeading)
                    local citizenid = Player.PlayerData.citizenid
                    local isDriving = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?', {plate, citizenid, 0})[1]
                    if isDriving and isDriving.plate == plate then MySQL.Async.execute('UPDATE player_vehicles SET location = ? WHERE plate = ? AND citizenid = ? AND state = ?', {json.encode(location), plate, citizenid, 0}) end
                end
            end
        end
    end
    SetTimeout(SV_Config.AutoSaveTimer * 1000, AutoSave)
end

QBCore.Functions.CreateCallback('mh-parkingV2:server:isVehicleParked', function(source, cb, plate, state)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE state = ?', {state})[1]
    if result then cb(true) end
    cb(false)
end)

QBCore.Functions.CreateCallback('mh-parkingV2:server:getVehicleData', function(source, cb, plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?', {citizenid, plate})[1]
        if result ~= nil and result.plate == plate then cb(result) else cb({owner = false, message = Lang:t('info.not_the_owner')}) end
    end
end)

QBCore.Functions.CreateCallback("mh-parkingV2:server:save", function(source, cb, plate, location, netid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        local isFound = false
        local totalParked = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?', {citizenid, 3})
        if type(totalParked) == 'table' and #totalParked < SV_Config.Maxparking then
            local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?', {plate, citizenid, 0})[1]
            if result ~= nil and result.plate == plate then
                local result2 = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?', {plate, citizenid, 3})
                if type(result2) == 'table' and #result2 > 0 then
                    cb({status = false, message = Lang:t('info.already_parked')})
                else
                    MySQL.Async.execute('UPDATE player_vehicles SET state = 3, location = ? WHERE plate = ? AND citizenid = ?', {json.encode(location), plate, citizenid})
                    cb({status = true, message = Lang:t('info.vehicle_parked')})
                end
            else
                cb({owner = false, message = Lang:t('info.not_the_owner')})
            end
        else
            cb({limit = true, message = Lang:t('info.limit_parking', {limit = SV_Config.Maxparking})})
        end
    end
end)

QBCore.Functions.CreateCallback("mh-parkingV2:server:drive", function(source, cb, plate, netid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND state = ? AND citizenid = ?', {plate, 3, citizenid})[1]
        if result ~= nil and result.plate == plate then
            MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ? AND citizenid = ?', {plate, citizenid})
            TriggerClientEvent("mh-parkingV2:client:deletePlate", -1, plate)
            cb({status = true, message = Lang:t('info.remove_vehicle_zone'), data = json.decode(result.mods)})
        else
            cb({status = false, message = Lang:t('info.not_the_owner')})
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then AutoSave() end
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local parked = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND state = ?', {plate, 3})[1]
    if parked then TriggerClientEvent('mh-parkingV2:client:deletePlate', -1, plate) end
end)

RegisterNetEvent("baseevents:enteredVehicle", function(currentVehicle, currentSeat, vehicleName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?', {citizenid, plate, 3})[1]
        if result then TriggerClientEvent('mh-parkingV2:client:autoDrive', -1, src, netId) end
    end
end)

RegisterNetEvent('baseevents:leftVehicle', function(currentVehicle, currentSeat, vehicleName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?', {citizenid, plate, 0})[1]
        if result then TriggerClientEvent('mh-parkingV2:client:autoPark', -1, src, netId) end
    end
end)

RegisterServerEvent('mh-parkingV2:server:refreshVehicles', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE state = 3')
        if type(result) == 'table' and #result >= 1 then
            local vehicles = {}
            for k, v in pairs(result) do
                vehicles[#vehicles + 1] = {citizenid = v.citizenid, plate = v.plate, model = v.vehicle, fuel = v.fuel, engine = v.engine, body = v.body, mods = json.decode(v.mods), location = json.decode(v.location)}
                if Player.PlayerData.citizenid == v.citizenid then TriggerClientEvent('qb-vehiclekeys:client:AddKeys', Player.PlayerData.source, v.plate) end
            end
            TriggerClientEvent("mh-parkingV2:client:refreshVehicles", src, vehicles)
        end
    end
end)
