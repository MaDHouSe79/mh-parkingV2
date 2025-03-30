Parking = {}
Parking.Functions = {}

function Parking.Functions.SetVehicleLockState(netid, state)
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(netid), state)
end

function Parking.Functions.GetClosestVehicle(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

function Parking.Functions.IsVehicleParked(plate, state)
    local result = nil
    if Config.Framework == 'esx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", {plate, 3})[1]
     elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", {plate, 3})[1]
    end
    if result then return true end
    return false
end

function Parking.Functions.GetVehicleData(src, plate)
    local Player = GetPlayer(src)
    if Player then
        local result = nil
        if Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ?", {Player.identifier, plate})[1]
         elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?", {Player.PlayerData.citizenid, plate})[1]
        end
        if result ~= nil and SamePlates(result.plate, plate) then
            return result
        else
            return {owner = false, message = Lang:t('info.not_the_owner')}
        end
    end
end

function Parking.Functions.GetVehicles(src)
    local Player = GetPlayer(src)
    if Player then
        if Config.Framework == 'esx' then
            local result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND stored = ?", {Player.identifier, 3})
            if result then return result else return nil end
         elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            local result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?", {Player.PlayerData.citizenid, 3})
            if result then return result else return nil end
        end
    end
end

function Parking.Functions.Save(src, data)
    local Player = GetPlayer(src)
    if Player then
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)
        if DoesEntityExist(vehicle) then
            local totalParked = nil
            if Config.Framework == 'esx' then
                totalParked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND stored = ?", {Player.identifier, 3})
             elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                totalParked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?", {Player.PlayerData.citizenid, 3})
            end
            if type(totalParked) == 'table' and #totalParked < Config.Maxparking then
                local result = nil
                if Config.Framework == 'esx' then
                    result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ? AND stored = ?", {data.plate, Player.identifier, 0})[1]
                 elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                    result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?", {data.plate, Player.PlayerData.citizenid, 0})[1]
                end
                if result ~= nil and SamePlates(result.plate, data.plate) then
                    local result2 = nil
                    if Config.Framework == 'esx' then
                        result2 = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ? AND stored = ?", {data.plate, Player.identifier, 3})
                     elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                        result2 = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?", {data.plate, Player.PlayerData.citizenid, 3})
                    end
                    if type(result2) == 'table' and #result2 > 0 then
                        return {status = false, message = Lang:t('info.already_parked')}
                    else
                        local citizenid, fullname, owned = nil, nil, nil
                        if Config.Framework == 'esx' then
                            citizenid, fullname = Player.identifier, Player.name
                            owned = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? LIMIT 1", {citizenid, data.plate})[1]
                            MySQL.Async.execute('UPDATE owned_vehicles SET stored = ?, location = ?, street = ?, fuel = ?, body = ?, engine = ? WHERE plate = ? AND owner = ?', {3, json.encode(data.location), data.street, data.fuel, data.body, data.engine, data.plate, citizenid})
                        elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                            citizenid, fullname = Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
                            owned = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? LIMIT 1", {citizenid, data.plate})[1]
                            MySQL.Async.execute('UPDATE player_vehicles SET state = ?, location = ?, street = ?, fuel = ?, body = ?, engine = ? WHERE plate = ? AND citizenid = ?', {3, json.encode(data.location), data.street, data.fuel, data.body, data.engine, data.plate, citizenid})
                        end
                        if owned.vehicle ~= nil then model = owned.vehicle else model = data.model end
                        local _data = {citizenid = citizenid, fullname = fullname, entity = vehicle, plate = data.plate, model = model, location = data.location, fuel = data.fuel, body = data.body, engine = data.engine}
                        TriggerClientEvent('mh-parkingV2:client:addVehicle', -1, _data)
                        return {status = true, message = Lang:t('info.vehicle_parked')}
                    end
                else
                    return {owner = false, message = Lang:t('info.not_the_owner')}
                end
            else
                return {limit = true, message = Lang:t('info.limit_parking', {limit = Config.Maxparking})}
            end
        end
    end
end

function Parking.Functions.Drive(src, data)
    local Player = GetPlayer(src)
    if Player then
        local result = nil
        if Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ? AND stored = ?", {data.plate, Player.identifier, 3})[1]
         elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?", {data.plate, Player.PlayerData.citizenid, 3})[1]
        end
        if result ~= nil and SamePlates(result.plate, data.plate) then
            if Config.Framework == 'esx' then
                MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0 WHERE plate = ? AND owner = ?', {data.plate, Player.identifier})
             elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ? AND citizenid = ?', {data.plate, Player.PlayerData.citizenid})
            end
            TriggerClientEvent("mh-parkingV2:client:deletePlate", -1, data.plate)
            return {status = true, message = Lang:t('info.remove_vehicle_zone'), data = json.decode(result.mods)}
        else
            return {status = false, message = Lang:t('info.not_the_owner')}
        end
    end
end

function Parking.Functions.Impound(src, plate)
    local Player = GetPlayer(src)
    if Player then
        if Player.PlayerData.job.name == 'police' then
            local parked = nil
            if Config.Framework == 'esx' then
                parked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", {plate, 3})[1]
             elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                parked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", {plate, 3})[1]
            end
            if parked then TriggerClientEvent('mh-parkingV2:client:deletePlate', -1, plate) end
        end
    end
end

function Parking.Functions.TowVehicle(src, plate)
    local Player = GetPlayer(src)
    if Player and Player.PlayerData.job.name == 'mechanic' then
        local parked = nil
        if Config.Framework == 'esx' then
            parked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", {plate, 3})[1]
         elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            parked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", {plate, 3})[1]
        end
        if parked then
            if Config.Framework == 'esx' then
                MySQL.Async.execute("UPDATE owned_vehicles SET stored = 0 WHERE plate = ?", {plate})
             elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                MySQL.Async.execute("UPDATE player_vehicles SET state = 0 WHERE plate = ?", {plate})
            end
            TriggerClientEvent('mh-parkingV2:client:deletePlate', -1, plate)
        end
    end
end

function Parking.Functions.EnteringVehicle(src, currentSeat, netId)
    local Player = GetPlayer(src)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = nil
        if Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", {Player.identifier, plate, 3})[1]
         elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", {Player.PlayerData.citizenid, plate, 3})[1]
        end
        if result then TriggerClientEvent('mh-parkingV2:client:autoDrive', -1, src, netId) end
    end
end

function Parking.Functions.LeftVehicle(src, currentSeat, netId)
    local Player = GetPlayer(src)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = nil
        if Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", {Player.identifier, plate, 0})[1]
         elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", {Player.PlayerData.citizenid, plate, 0})[1]
        end
        if result then TriggerClientEvent('mh-parkingV2:client:autoPark', -1, src, netId) end
    end
end

function GetVehicleList()
    local result = nil
    local vehicles = {}
    if Config.Framework == 'esx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE stored = ?", {3})
    elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE state = ?", {3})
    end
    if type(result) == 'table' then
        for k, v in pairs(result) do
            local fullname = "unknow"
            if Config.Framework == 'esx' then
                local char = MySQL.Sync.fetchAll("SELECT * FROM users WHERE owner = ?", {v.citizenid})[1]
                if char then fullname = char.firstname.. ' ' ..char.lastname end
                local tmpVehicles = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE stored = ? AND owner = ?", {3, v.citizenid})[1]
                local mods = json.decode(tmpVehicles.vehicle)
                local coords = json.decode(tmpVehicles.location)
                vehicles[#vehicles + 1] = {citizenid = tmpVehicles.owner, fullname = fullname, plate = tmpVehicles.plate, model = mods.model, fuel = mods.fuelLevel, engine = mods.engineHealth, body = mods.bodyHealth, mods = mods, location = coords}
             elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                local target = Framework.Functions.GetPlayerByCitizenId(v.citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(v.citizenid)
                fullname = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
                local tmpVehicles = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE state = ? and plate = ?", {3, v.plate})[1]
                local mods = json.decode(tmpVehicles.mods)
                local coords = json.decode(tmpVehicles.location)
                vehicles[#vehicles + 1] = {citizenid = tmpVehicles.citizenid, fullname = fullname, plate = tmpVehicles.plate, model = tmpVehicles.vehicle, fuel = tmpVehicles.fuel, engine = tmpVehicles.engine, body = tmpVehicles.body, mods = mods, location = coords}
            end
        end
    end
    return vehicles
end

local lock = false
function Parking.Functions.RefreshVehicles(src, onStart)
    local playerId = -1
    if onStart then
        if lock then return end
        lock = true
        local players = GetPlayers()
        local player = players[math.random(1, #players)]
        playerId = player.PlayerData.source
    elseif not onStart then
        playerId = src
    end
    if playerId ~= -1 then
        local vehicles = CreateVehicleList()
        Wait(50)
        TriggerClientEvent("mh-parkingV2:client:refreshVehicles", playerId, vehicles)
    end
end

function Parking.Functions.Init()
    Wait(3000)
    if Config.Framework == 'esx' then
        -- ESX Database
        MySQL.Async.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS parkvip INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS parkmax INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
     elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
        --- QBCore Database
        MySQL.Async.execute('ALTER TABLE players ADD COLUMN IF NOT EXISTS parkvip INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE players ADD COLUMN IF NOT EXISTS parkmax INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
    end
end
