--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
local QBCore = exports['qb-core']:GetCoreObject()
local parkedVehicles = {}

local function AutoSave()
    local players = QBCore.Functions.GetPlayers()
    if Config.AutoSave and #players >= 1 then
        for src in pairs(players) do
            local Player = QBCore.Functions.GetPlayer(src)
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
                    if isDriving and isDriving.plate == plate then
                        MySQL.Async.execute('UPDATE player_vehicles SET location = ?, street = ? WHERE plate = ? AND citizenid = ? AND state = ?', {json.encode(location), 'unknow', plate, citizenid, 0}) 
                    end
                end
            end
        end
    end
    SetTimeout(Config.AutoSaveTimer * 1000, AutoSave)
end

local function RemoveParkedVehicle(plate)
    for k, v in pairs(parkedVehicles) do
        if v.plate == plate then
            parkedVehicles[k] = nil
        end
    end
end

QBCore.Functions.CreateCallback('mh-parkingV2:server:isVehicleParked', function(source, cb, plate)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE state = ? AND plate = ?', {plate})[1]
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

QBCore.Functions.CreateCallback("mh-parkingV2:server:GetVehicles", function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?", {Player.PlayerData.citizenid, 3})
        if result then cb(result) else cb(nil) end
    end
end)

QBCore.Functions.CreateCallback("mh-parkingV2:server:save", function(source, cb, plate, location, netid, model, street)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local vehicle = NetworkGetEntityFromNetworkId(netid)
        if DoesEntityExist(vehicle) then
            local citizenid = Player.PlayerData.citizenid
            local isFound = false
            local totalParked = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?', {citizenid, 3})
            if type(totalParked) == 'table' and #totalParked < Config.Maxparking then
                local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?', {plate, citizenid, 0})[1]
                if result ~= nil and result.plate == plate then
                    local result2 = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?', {plate, citizenid, 3})
                    local status
                    local message
                    if type(result2) == 'table' and #result2 > 0 then
                        status = false
                        message = Lang:t('info.already_parked')
                    else
                        MySQL.Async.execute('UPDATE player_vehicles SET state = 3, location = ?, street = ? WHERE plate = ? AND citizenid = ?', {json.encode(location), street, plate, citizenid})
                        status = true
                        message = Lang:t('info.vehicle_parked')
                    end
                    local fullname = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
                    TriggerClientEvent('mh-parkingV2:client:addVehicle', -1, {citizenid = citizenid, fullname = fullname, plate = plate, model = model, steet = street, location = location, entity = vehicle})
                    cb({status = status, message = message})
                else
                    cb({owner = false, message = Lang:t('info.not_the_owner')})
                end
            else
                cb({limit = true, message = Lang:t('info.limit_parking', {limit = Config.Maxparking})})
            end
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
    if resource == GetCurrentResourceName() then
        AutoSave()
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles')
        for k, v in pairs(result) do
            if v.state == 0 and (v.location ~= nil) then
                MySQL.update('UPDATE player_vehicles SET state = 3 WHERE plate = ?', {v.plate})
            end
        end
    end
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        if Player.PlayerData.job.type == 'leo' and Player.PlayerData.job.onduty then
            local parked = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND state = 3', {plate})[1]
            if parked then TriggerClientEvent('mh-parkingV2:client:deletePlate', -1, plate) end
        end 
    end
end)

RegisterNetEvent('mh-parkingV2:server:TowVehicle', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        if Player.PlayerData.job.name == 'mechanic' and Player.PlayerData.job.onduty then
            local parked = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ? AND state = ?', {plate})[1]
            if parked then 
                MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ?', {plate})
                TriggerClientEvent('mh-parkingV2:client:deletePlate', -1, plate)
            end
        end
    end
end)

RegisterNetEvent("mh-parkingV2:server:enteredVehicle", function(currentVehicle, currentSeat, vehicleName, netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?', {citizenid, plate, 3})[1]
        if result then TriggerClientEvent('mh-parkingV2:client:autoDrive', -1, src, netId) end
    end
end)

RegisterNetEvent('mh-parkingV2:server:leftVehicle', function(currentVehicle, currentSeat, vehicleName, netId)
    local src = source
    if Config.AutoSaveWhenLeaveVehicle then
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(vehicle) and currentSeat == -1 then
            local citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
            local plate = GetVehicleNumberPlateText(vehicle)
            local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?', {citizenid, plate, 0})[1]
            if result then TriggerClientEvent('mh-parkingV2:client:autoPark', -1, src, netId) end
        end
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
                local fullname = "unknow"
                local pl = MySQL.Sync.fetchAll('SELECT * FROM players WHERE citizenid = ?', {v.citizenid})[1]
                if pl then
                    local user = json.decode(pl.charinfo)
                    fullname = user.firstname .. ' ' .. user.lastname
                end
                vehicles[#vehicles + 1] = {citizenid = v.citizenid, fullname = fullname, plate = v.plate, model = v.vehicle, fuel = v.fuel, engine = v.engine, body = v.body, mods = json.decode(v.mods), location = json.decode(v.location), steet = v.street}                
                if Player.PlayerData.citizenid == v.citizenid then TriggerClientEvent('qb-vehiclekeys:client:AddKeys', Player.PlayerData.source, v.plate) end
            end
            parkedVehicles = vehicles
            TriggerClientEvent("mh-parkingV2:client:refreshVehicles", src, vehicles)
        end
    end
end)

RegisterNetEvent('mh-parkingV2:server:setVehLockState', function(vehNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), state)
    end
end)

CreateThread(function()
    Wait(3000)
    if Config.Framework == 'esx' then
        -- ESX Database
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
    elseif Config.Framework == 'qb' then
        --- QBCore Database
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
    end
end)