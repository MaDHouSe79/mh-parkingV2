--[[ ===================================================== ]] --
--[[               MH Parking V2 by MaDHouSe79             ]] --
--[[ ===================================================== ]] --
Parking = {}
Parking.Functions = {}

function Parking.Functions.GetVehicles(src)
	local xPlayer = GetPlayer(src)
	local citizenid = GetCitizenId(src)
	if xPlayer then
		local result = nil
		if Config.Framework == 'esx' then
			result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? ORDER BY vehicle ASC", { citizenid })
			result.state = result.stored
		elseif Config.Framework == 'qb' then
			result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? ORDER BY vehicle ASC", { citizenid })
		end
		if result then return result else return nil end
	end
end

function Parking.Functions.RefreshVehicles(src)
	if src == nil then src = -1 end
	local vehicles = {}
	local result = nil
	if Config.Framework == 'esx' then
		result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE stored = 3")
	elseif Config.Framework == 'qb' then
		result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE state = 3")
	end
	for k, v in pairs(result) do
		if Config.Framework == 'esx' then
			local char = MySQL.Sync.fetchAll("SELECT * FROM users WHERE owner = ?", {v.citizenid})[1]
			if char and v.fullname == nil then v.fullname = char.firstname .. ' ' .. char.lastname end
		elseif Config.Framework == 'qb' then
			local target = GetPlayerDataByCitizenId(v.citizenid)
			if v.fullname == nil then v.fullname = target.PlayerData.charinfo.firstname ..' ' .. target.PlayerData.charinfo.lastname end
		end
		vehicles[#vehicles + 1] = {
			fullname = v.fullname,
			owner = v.citizenid,
			vehicle = v.vehicle,
			plate = v.plate,
			fuel = v.fuel,
			body = v.body,
			engine = v.engine,
			street = v.street,
			steerangle = v.steerangle,
			mods = json.decode(v.mods),
			location = json.decode(v.location),
			trailerdata = json.decode(v.trailerdata),
		}
		if Config.Framework == 'qb' then
			local target = GetPlayerDataByCitizenId(v.citizenid)
			if target.PlayerData.citizenid == v.citizenid and target.PlayerData.source ~= nil then
				if DoesEntityExist(GetPlayerPed(target.PlayerData.source)) then
					if GetResourceState("qb-vehiclekeys") ~= 'missing' then
						exports['qb-vehiclekeys']:GiveKeys(target.PlayerData.source, v.plate)
					end
				end
			end
		end
	end
	TriggerClientEvent("mh-parkingV2:client:RefreshVehicles", src, vehicles)
end

function Parking.Functions.IfPlayerIsVIPGetMaxParking(src)
	local Player = GetPlayer(src)
	local citizenid = GetCitizenId(src)
	local max = Config.Maxparking
	if Player then
		local data = nil
		if Config.Framework == 'esx' then
			data = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = ?", { citizenid })[1]
		elseif Config.Framework == 'qb' then
			data = MySQL.Sync.fetchAll("SELECT * FROM players WHERE citizenid = ?", { citizenid })[1]
		end
		if data ~= nil and data.parkvip == 1 then
			max = data.parkmax
		end
	end
	return max
end

function Parking.Functions.Save(src, data)
	local xPlayer = GetPlayer(src)
	local citizenid = GetCitizenId(src)
	local totalParked = nil
	if Config.Framework == 'esx' then
		totalParked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND stored = ?", { citizenid, 3 })
	elseif Config.Framework == 'qb' then
		totalParked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?", { citizenid, 3 })
	end
	local defaultMax = Config.Maxparking
	if Config.UseAsVip then defaultMax = Parking.Functions.IfPlayerIsVIPGetMaxParking(src) end
	if type(totalParked) == 'table' and #totalParked < defaultMax then
		local fullname = GetCitizenFullname(src)
		local plate = data.plate
		local isParked = nil
		if Config.Framework == 'esx' then
			isParked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", { citizenid, plate, 3 })[1]
		elseif Config.Framework == 'qb' then
			isParked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", { citizenid, plate, 3 })[1]
		end
		if isParked ~= nil then
			return { status = false, message = Lang:t('info.already_parked') }
		else
			local result = nil
			if Config.Framework == 'esx' then
				result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ?", { citizenid, plate })[1]
			elseif Config.Framework == 'qb' then
				result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?", { citizenid, plate })[1]
			end
			if result ~= nil then
				local location = json.encode(data.location)
				local trailerdata = nil
				if data.trailerdata ~= nil then trailerdata = json.encode(data.trailerdata) end
				if Config.Framework == 'esx' then
					MySQL.Async.execute('UPDATE owned_vehicles SET stored = ?, location = ?, street = ?, trailerdata = ?, steerangle = ? WHERE plate = ? AND stored = ?', { 3, location, data.street, trailerdata, data.steerangle, plate, citizenid })
				elseif Config.Framework == 'qb' then
					MySQL.Async.execute('UPDATE player_vehicles SET state = ?, location = ?, street = ?, trailerdata = ?, steerangle = ?, engine = ?, fuel = ?, body = ? WHERE plate = ? AND citizenid = ?', { 3, location, data.street, trailerdata, data.steerangle, data.engine, data.fuel, data.body, plate, citizenid })
				end
				Wait(100)
				TriggerClientEvent("mh-parkingV2:client:AddVehicle", -1, {
					vehicle = result.vehicle,
					plate = result.plate,
					owner = result.citizenid,
					fullname = fullname,
					street = result.street,
					engine = result.engine,
					fuel = result.fuel,
					body = result.body,
					steerangle = data.steerangle,
					location = data.location,
					mods = json.decode(result.mods),
					trailerdata = json.decode(trailerdata),
				}, src)
				return { status = true, message = Lang:t('info.vehicle_parked') }
			else
				return {status = false, message = Lang:t('info.not_the_owner')}
			end
		end
	else
		return { status = false, message = Lang:t('info.limit_parking', {limit=defaultMax}) }
	end
end

function Parking.Functions.Drive(src, data)
	local xPlayer = GetPlayer(src)
	local plate = data.plate
	local result = nil
	if Config.Framework == 'esx' then
		result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", { xPlayer.identifier, plate, 3 })[1]
	elseif Config.Framework == 'qb' then
		result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", { xPlayer.PlayerData.citizenid, plate, 3 })[1]
	end
	if result ~= nil then
		local mods = json.decode(result.mods)
		local location = json.decode(result.location)
		local trailerdata = json.decode(result.trailerdata)
		if Config.Framework == 'esx' then
			MySQL.Async.execute('UPDATE owned_vehicles SET stored = ?, location = ?, steerangle = ? WHERE plate = ?', { 0, nil, 0, plate })
		elseif Config.Framework == 'qb' then
			MySQL.Async.execute('UPDATE player_vehicles SET state = ?, location = ?, steerangle = ? WHERE plate = ?', { 0, nil, 0, plate })
		end
		Wait(50)
		TriggerClientEvent("mh-parkingV2:client:DeleteVehicle", -1, { plate = plate })
		return { status = true, message = Lang:t('info.remove_vehicle_zone'), vehicle = result.vehicle, mods = mods, plate = result.plate, location = location, fuel = result.fuel, body = result.body, engine = result.engine, trailerdata = trailerdata }
	else
		return { status = false, message = Lang:t('info.no_vehicles_parked') }
	end
end

function Parking.Functions.CreateOwnerVehicleBlip(src, plate)
	local xPlayer = GetPlayer(src)
	local result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ?", { xPlayer.PlayerData.citizenid, plate })[1]
	if result then TriggerClientEvent("mh-parkingV2:client:CreateOwnerVehicleBlip", src, { vehicle = result.vehicle, location = json.decode(result.location), plate = result.plate }) end
end

function Parking.Functions.OnJoin(src)
	TriggerClientEvent('mh-parkingV2:client:OnJoin', src)
end

function Parking.Functions.GetTrailerLoad(src, data)
	local xPlayer = GetPlayer(src)
	local plate = data.plate
	local result = nil
	if Config.Framework == 'esx' then
		result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ?", { plate })[1]
	elseif Config.Framework == 'qb' then
		result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ?", { plate })[1]
	end
	if result ~= nil then
		local trailerdata = json.decode(result.trailerdata)
		if trailerdata ~= nil then
			if trailerdata.load ~= nil then
				return {status = true, load = trailerdata.load }
			else
				return {status = false, load = nil }
			end
		else
			return {status = false, load = nil }
		end
	else
		return {status = false, load = nil }
	end
end

function Parking.Functions.Init()
	Wait(3000)
	if Config.Framework == 'esx' then
		-- ESX Database
		MySQL.Async.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS parkvip INT NULL DEFAULT 0')
		MySQL.Async.execute('ALTER TABLE users ADD COLUMN IF NOT EXISTS parkmax INT NULL DEFAULT 0')
		MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS steerangle INT NULL DEFAULT 0')
		MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
		MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
		MySQL.Async.execute('ALTER TABLE owned_vehicles ADD COLUMN IF NOT EXISTS trailerdata LONGTEXT NULL DEFAULT NULL')
	elseif Config.Framework == 'qb' then
		--- QBCore Database
		MySQL.Async.execute('ALTER TABLE players ADD COLUMN IF NOT EXISTS parkvip INT NULL DEFAULT 0')
		MySQL.Async.execute('ALTER TABLE players ADD COLUMN IF NOT EXISTS parkmax INT NULL DEFAULT 0')
		MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS steerangle INT NULL DEFAULT 0')
		MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL')
		MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL')
		MySQL.Async.execute('ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS trailerdata LONGTEXT NULL DEFAULT NULL')
	end
end

AddCommand("addvip", Lang:t('commands.addvip'), { { name = 'ID', help = Lang:t('commands.addvip_info') }, { name = 'Amount', help = Lang:t('commands.addvip_info_amount') } }, true, function(source, args)
	local src, amount, targetID = source, Config.Maxparking, -1
	if args[1] and tonumber(args[1]) > 0 then targetID = tonumber(args[1]) end
	if args[2] and tonumber(args[2]) > 0 then amount = tonumber(args[2]) end
	if targetID ~= -1 then
		local Player = GetPlayer(targetID)
		if Player then
			if Config.Framework == 'esx' then
				MySQL.Async.execute("UPDATE users SET parkvip = ?, parkmax = ? WHERE owner = ?", { 1, amount, Player.identifier })
				if targetID ~= src then Notify(targetID, Lang:t('info.playeraddasvip'), "success", 10000) end
				Notify(src, Lang:t('info.isaddedasvip'), "success", 10000)
			elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
				MySQL.Async.execute("UPDATE players SET parkvip = ?, parkmax = ? WHERE citizenid = ?", { 1, amount, Player.PlayerData.citizenid })
				if targetID ~= src then Notify(targetID, Lang:t('info.playeraddasvip'), "success", 10000) end
				Notify(src, Lang:t('info.isaddedasvip'), "success", 10000)
			end
		end
	end
end, 'admin')

AddCommand("removevip", Lang:t('commands.removevip'), { { name = 'ID', help = Lang:t('commands.removevip_info') } }, true, function(source, args)
	local src, targetID = source, -1
	if args[1] and tonumber(args[1]) > 0 then targetID = tonumber(args[1]) end
	if targetID ~= -1 then
		local Player = GetPlayer(targetID)
		if Player then
			if Config.Framework == 'esx' then
				MySQL.Async.execute("UPDATE users SET parkvip = ?, parkmax = ? WHERE owner = ?", { 0, 0, Player.identifier })
				Notify(src, Lang:t('info.playerremovedasvip'), "success", 10000)
			elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
				MySQL.Async.execute("UPDATE players SET parkvip = ?, parkmax = ? WHERE citizenid = ?", { 0, 0, Player.PlayerData.citizenid })
				Notify(src, Lang:t('info.playerremovedasvip'), "success", 10000)
			end
		end
	end
end, 'admin')

------------------------------------------------------------------------------
function Parking.Functions.Impound(src, plate)
    local Player = GetPlayer(src)
    if Player then
        if Player.PlayerData.job.name == 'police' then
            local parked = nil
            if Config.Framework == 'esx' then
                parked = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE plate = ? AND stored = ?", { plate, 3 })[1]
            elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                parked = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate = ? AND state = ?", { plate, 3 })[1]
            end
            if parked then TriggerClientEvent('mh-parkingV2:client:DeletePlate', -1, plate) end
        end
    end
end

function Parking.Functions.EnteringVehicle(src, currentVehicle, currentSeat, vehicleName, netId)
	local Player = GetPlayer(src)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	if DoesEntityExist(vehicle) and currentSeat == -1 then
		local plate = GetVehicleNumberPlateText(vehicle)
		local result = nil
		if Config.Framework == 'esx' then
			result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", { Player.identifier, plate, 3 })[1]
		elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
			result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", { Player.PlayerData.citizenid, plate, 3 })[1]
		end
		if result then TriggerClientEvent('mh-parkingV2:client:AutoDrive', -1, src) end
	end
end

function Parking.Functions.LeftVehicle(src, currentVehicle, currentSeat, vehicleName, netId)
	local Player = GetPlayer(src)
	local vehicle = NetworkGetEntityFromNetworkId(netId)
	if DoesEntityExist(vehicle) then
		local plate = GetVehicleNumberPlateText(vehicle)
		local result = nil
		if Config.Framework == 'esx' then
			result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = ?", { Player.identifier, plate, 0 })[1]
		elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
			result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE citizenid = ? AND plate = ? AND state = ?", { Player.PlayerData.citizenid, plate, 0 })[1]
		end
		if result then TriggerClientEvent('mh-parkingV2:client:AutoPark', -1, src) end
	end
end