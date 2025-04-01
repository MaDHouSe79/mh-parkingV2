Parking = {}
Parking.Functions = {}

function Parking.Functions.OnJoin(src)
    TriggerClientEvent('mh-parkingV2:client:OnJoin', src, SV_Config)
end

function Parking.Functions.SetVehicleLockState(netid, state)
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(netid), state)
end

function Parking.Functions.IsVehicleParked(plate, state)
    local result = nil
    if SV_Config.Framework == 'esx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", { plate, 3 })[1]
    elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", { plate, 3 })[1]
    end
    if result then return true end
    return false
end

function Parking.Functions.GetVehicleData(src, plate)
    local Player = GetPlayer(src)
    if Player then
        local result = nil
        if SV_Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ?", { Player.identifier, plate })[1]
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?", { Player.PlayerData.citizenid, plate })[1]
        end
        if result ~= nil and SamePlates(result.plate, plate) then
            return result
        else
            return { owner = false, message = Lang:t('info.not_the_owner') }
        end
    end
end

function Parking.Functions.GetVehicles(src)
    local Player = GetPlayer(src)
    if Player then
        if SV_Config.Framework == 'esx' then
            local result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND stored = ?", { Player.identifier, 3 })
            if result then return result else return nil end
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            local result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?", { Player.PlayerData.citizenid, 3 })
            if result then return result else return nil end
        end
    end
end

function Parking.Functions.IfPlayerIsVIPGetMaxParking(src)
    local Player = GetPlayer(src)
    local max = SV_Config.Maxparking
    if Player then
        local data = nil
        if SV_Config.Framework == 'esx' then
            data = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = ?", {Player.identifier})[1]
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            data = MySQL.Sync.fetchAll("SELECT * FROM players WHERE citizenid = ?", {Player.PlayerData.citizenid})[1]
        end
        if data ~= nil and data.parkvip == 1 then
            max = data.parkmax
        end
    end
    return max
end

function Parking.Functions.Save(src, data)
    local Player = GetPlayer(src)
    if Player then
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)
        if DoesEntityExist(vehicle) then
            local totalParked = nil
            if SV_Config.Framework == 'esx' then
                totalParked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND stored = ?", { Player.identifier, 3 })
            elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                totalParked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?", { Player.PlayerData.citizenid, 3 })
            end
            local defaultMax = SV_Config.Maxparking
            if SV_Config.UseAsVip then defaultMax = Parking.Functions.IfPlayerIsVIPGetMaxParking(src) end
            if type(totalParked) == 'table' and #totalParked < defaultMax then
                local result = nil
                if SV_Config.Framework == 'esx' then
                    result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ? AND stored = ?", { data.plate, Player.identifier, 0 })[1]
                elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                    result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?", { data.plate, Player.PlayerData.citizenid, 0 })[1]
                end
                if result ~= nil and SamePlates(result.plate, data.plate) then
                    local result2 = nil
                    if SV_Config.Framework == 'esx' then
                        result2 = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ? AND stored = ?", { data.plate, Player.identifier, 3 })
                    elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                        result2 = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?", { data.plate, Player.PlayerData.citizenid, 3 })
                    end
                    if type(result2) == 'table' and #result2 > 0 then
                        return { status = false, message = Lang:t('info.already_parked') }
                    else
                        local citizenid, fullname, owned, trailerdata = nil, nil, nil, nil
                        if data.trailerdata ~= nil then trailerdata = json.encode(data.trailerdata) end
                        if SV_Config.Framework == 'esx' then
                            citizenid, fullname = Player.identifier, Player.name
                            owned = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? LIMIT 1", { citizenid, data.plate })[1]
                            MySQL.Async.execute('UPDATE owned_vehicles SET stored = ?, location = ?, street = ?, fuel = ?, body = ?, engine = ?, steerangle = ?, trailerdata = ? WHERE plate = ? AND owner = ?', { 3, json.encode(data.location), data.street, data.fuel, data.body, data.engine, data.steerangle, trailerdata, data.plate, citizenid })
                        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                            citizenid, fullname = Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
                            owned = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? LIMIT 1", { citizenid, data.plate })[1]
                            MySQL.Async.execute('UPDATE player_vehicles SET state = ?, location = ?, street = ?, fuel = ?, body = ?, engine = ?, steerangle = ?, trailerdata = ? WHERE plate = ? AND citizenid = ?', { 3, json.encode(data.location), data.street, data.fuel, data.body, data.engine, data.steerangle, trailerdata, data.plate, citizenid })
                        end
                        if owned.vehicle ~= nil then model = owned.vehicle else model = data.model end
                        local _data = { citizenid = citizenid, fullname = fullname, entity = vehicle, plate = data.plate, model = model, location = data.location, fuel = data.fuel, body = data.body, engine = data.engine, steerangle = data.steerangle }
                        TriggerClientEvent('mh-parkingV2:client:AddVehicle', -1, _data)
                        return { status = true, message = Lang:t('info.vehicle_parked') }
                    end
                else
                    return { owner = false, message = Lang:t('info.not_the_owner') }
                end
            else
                return { limit = true, message = Lang:t('info.limit_parking', { limit = SV_Config.Maxparking }) }
            end
        end
    end
end

function Parking.Functions.Drive(src, data)
    local Player = GetPlayer(src)
    if Player then
        local result = nil
        if SV_Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ? AND stored = ?", { data.plate, Player.identifier, 3 })[1]
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ? AND state = ?", { data.plate, Player.PlayerData.citizenid, 3 })[1]
        end
        if result ~= nil and SamePlates(result.plate, data.plate) then
            if SV_Config.Framework == 'esx' then
                MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0, location = ?, street = ?, trailerdata = ?, steerangle = ? WHERE plate = ? AND owner = ?', {nil, nil, nil, 0, data.plate, Player.identifier })
            elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                MySQL.Async.execute('UPDATE player_vehicles SET state = 0, location = ?, street = ?, trailerdata = ?, steerangle = ? WHERE plate = ? AND citizenid = ?', {nil, nil, nil, 0, data.plate, Player.PlayerData.citizenid })
            end
            TriggerClientEvent("mh-parkingV2:client:DeletePlate", -1, data.plate)
            return { status = true, message = Lang:t('info.remove_vehicle_zone'), data = json.decode(result.mods) }
        else
            return { status = false, message = Lang:t('info.not_the_owner') }
        end
    end
end

function Parking.Functions.Impound(src, plate)
    local Player = GetPlayer(src)
    if Player then
        if Player.PlayerData.job.name == 'police' then
            local parked = nil
            if SV_Config.Framework == 'esx' then
                parked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", { plate, 3 })[1]
            elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                parked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", { plate, 3 })[1]
            end
            if parked then TriggerClientEvent('mh-parkingV2:client:DeletePlate', -1, plate) end
        end
    end
end

function Parking.Functions.TowVehicle(src, plate)
    local Player = GetPlayer(src)
    if Player and Player.PlayerData.job.name == 'mechanic' then
        local parked = nil
        if SV_Config.Framework == 'esx' then
            parked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", { plate, 3 })[1]
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            parked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", { plate, 3 })[1]
        end
        if parked then
            if SV_Config.Framework == 'esx' then
                MySQL.Async.execute("UPDATE owned_vehicles SET stored = 0 WHERE plate = ?", { plate })
            elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                MySQL.Async.execute("UPDATE player_vehicles SET state = 0 WHERE plate = ?", { plate })
            end
            TriggerClientEvent('mh-parkingV2:client:DeletePlate', -1, plate)
        end
    end
end

function Parking.Functions.EnteringVehicle(src, currentSeat, netId)
    local Player = GetPlayer(src)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = nil
        if SV_Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", { Player.identifier, plate, 3 })[1]
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", { Player.PlayerData.citizenid, plate, 3 })[1]
        end
        if result then TriggerClientEvent('mh-parkingV2:client:AutoDrive', -1, src, netId) end
    end
end

function Parking.Functions.LeftVehicle(src, currentSeat, netId)
    local Player = GetPlayer(src)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) and currentSeat == -1 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local result = nil
        if SV_Config.Framework == 'esx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", { Player.identifier, plate, 0 })[1]
        elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
            result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", { Player.PlayerData.citizenid, plate, 0 })[1]
        end
        if result then TriggerClientEvent('mh-parkingV2:client:AutoPark', -1, src, netId) end
    end
end

local fistjoin = true
triggerede = false
function Parking.Functions.RefreshVehicles(src, onStart)
    print('---------- REFRESH VEHICLES ----------')
    if onStart then
        print('onStart')
        if fistjoin then
            print('fistjoin'..src)
            fistjoin = false
            GetSinglePlayerId()
        end
    elseif not onStart then
        print('not onStart')
        if fistjoin then
            print('fistjoin'..src)
            fistjoin = false
            playerId = src
        end
    end
    Wait(50)
    if triggerede then return end
    if playerId ~= -1 then
        print(playerId..'spawned')
        triggerede = true
        local vehicles = CreateVehicleList()
        Wait(50)
        TriggerClientEvent("mh-parkingV2:client:RefreshVehicles", playerId, vehicles)
    end
end

function Parking.Functions.ClearAllSeats(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        TriggerClientEvent("mh-parkingV2:client:ClearAllSeats", -1, netid)
    end
end

function Parking.Functions.Init()
    Wait(3000)
    if SV_Config.Framework == 'esx' then
        -- ESX Database
        MySQL.Async.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS parkvip INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS parkmax INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS steerangle INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS trailerdata LONGTEXT NULL DEFAULT NULL')

    elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
        --- QBCore Database
        MySQL.Async.execute('ALTER TABLE players ADD COLUMN IF NOT EXISTS parkvip INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE players ADD COLUMN IF NOT EXISTS parkmax INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS steerangle INT NULL DEFAULT 0')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
        MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS trailerdata LONGTEXT NULL DEFAULT NULL')
    end
end

AddCommand("addvip", Lang:t('commands.addvip'), {{ name = 'ID', help = Lang:t('commands.addvip_info') }, { name = 'Amount', help = Lang:t('commands.addvip_info_amount')}}, true, function(source, args)
    local src, amount, targetID = source, SV_Config.Maxparking, -1
    if args[1] and tonumber(args[1]) > 0 then targetID = tonumber(args[1]) end
    if args[2] and tonumber(args[2]) > 0 then amount = tonumber(args[2]) end
    if targetID ~= -1 then
        local Player = GetPlayer(targetID)
        if Player then
            if SV_Config.Framework == 'esx' then
                MySQL.Async.execute("UPDATE users SET parkvip = ?, parkmax = ? WHERE owner = ?", {1, amount, Player.identifier})
                if targetID ~= src then Notify(targetID, Lang:t('info.playeraddasvip'), "success", 10000) end
                Notify(src, Lang:t('info.isaddedasvip'), "success", 10000)
            elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                MySQL.Async.execute("UPDATE players SET parkvip = ?, parkmax = ? WHERE citizenid = ?", {1, amount, Player.PlayerData.citizenid})
                if targetID ~= src then Notify(targetID, Lang:t('info.playeraddasvip'), "success", 10000) end
                Notify(src, Lang:t('info.isaddedasvip'), "success", 10000)
            end
        end
    end
end, 'admin')

AddCommand("removevip", Lang:t('commands.removevip'), {{ name = 'ID', help = Lang:t('commands.removevip_info')}}, true, function(source, args)
    local src, targetID = source, -1
    if args[1] and tonumber(args[1]) > 0 then targetID = tonumber(args[1]) end
    if targetID ~= -1 then
        local Player = GetPlayer(targetID)
        if Player then
            if SV_Config.Framework == 'esx' then
                MySQL.Async.execute("UPDATE users SET parkvip = ?, parkmax = ? WHERE owner = ?", {0, 0, Player.identifier})
                Notify(src, Lang:t('info.playerremovedasvip'), "success", 10000)
            elseif SV_Config.Framework == 'qb' or SV_Config.Framework == 'qbx' then
                MySQL.Async.execute("UPDATE players SET parkvip = ?, parkmax = ? WHERE citizenid = ?", {0, 0, Player.PlayerData.citizenid})
                Notify(src, Lang:t('info.playerremovedasvip'), "success", 10000)
            end
        end
    end
end, 'admin')