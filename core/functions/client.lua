--[[ ===================================================== ]] --
--[[               MH Parking V2 by MaDHouSe79             ]] --
--[[ ===================================================== ]] --
Parking = {}
Parking.Functions = {}
Parking.TrailerData = {}
diableParkedBlips = {}
parkMenu = nil
trailerLoad = {}
isInVehicle = false
currentVehicle = 0
currentSeat = 0
currentTruck = -1
currentTrailer = -1
isRampDown = false
isPlatformDown = false

function Parking.Functions.AddToTable(entity, data)
	LocalVehicles[#LocalVehicles + 1] = {
		entity = entity,
		fuel = data.fuel,
		body = data.body,
		engine = data.engine,
		mods = data.mods,
		plate = data.plate,
		owner = data.owner,
		fullname = data.fullname,
		location = data.location,
		steerangle = data.steerangle,
		trailerEntity = data.trailerEntity,
		trailerdata = data.trailerdata,
	}
end

function Parking.Functions.MakeVehiclesVisable()
	if isLoggedIn and Config.ViewDistance and #LocalVehicles > 0 then
		local playerCoords = GetEntityCoords(PlayerPedId())
		for k, v in pairs(LocalVehicles) do
			if GetDistance(playerCoords, v.location) < 150 and not IsEntityVisible(v.entity) then
				SetEntityVisible(v.entity, true)
				if v.trailerEntity ~= nil then SetEntityVisible(v.trailerEntity, true) end
			elseif GetDistance(playerCoords, v.location) > 150 and IsEntityVisible(v.entity) then
				SetEntityVisible(v.entity, false)
				if v.trailerEntity ~= nil then SetEntityVisible(v.trailerEntity, false) end
			end
		end
	end
end

function Parking.Functions.CheckDistanceToForceGrounded()
	if isLoggedIn and Config.ForceVehicleOnGound and #LocalVehicles > 0 then
		for i = 1, #LocalVehicles do
			if type(LocalVehicles[i]) == 'table' then
				local playerCoords = GetEntityCoords(PlayerPedId())
				if LocalVehicles[i].entity ~= nil and DoesEntityExist(LocalVehicles[i].entity) and not LocalVehicles[i].isGrounded then
					if GetVehicleWheelSuspensionCompression(LocalVehicles[i].entity) == 0 or GetDistance(playerCoords, LocalVehicles[i].location) < 150 then
						SetEntityCoords(LocalVehicles[i].entity, LocalVehicles[i].location.x, LocalVehicles[i].location.y, LocalVehicles[i].location.z)
						SetVehicleOnGroundProperly(LocalVehicles[i].entity)
						LocalVehicles[i].isGrounded = true
					end
				end
				Wait(100)
			end
		end
	end
end

function Parking.Functions.BlinkVehiclelights(vehicle, state)
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
	TriggerServerEvent('mh-parkingV2:server:SetVehLockState', VehToNet(vehicle), state)
	SetVehicleDoorsLocked(vehicle, state)
	if IsEntityPlayingAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3) then
		DeleteObject(object)
		StopAnimTask(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 8.0)
	end
	Wait(1000)
	if state then
		SetEntityInvincible(vehicle, true)
	else
		SetEntityInvincible(vehicle, false)
	end
end

function Parking.Functions.GetPedInStoredCar(ped)
	local findVeh = false
	for i = 1, #LocalVehicles do
		if LocalVehicles[i] ~= nil and LocalVehicles[i].entity == GetVehiclePedIsIn(ped) then
			findVeh = LocalVehicles[i]
			break
		end
	end
	return findVeh
end

function Parking.Functions.DeleteNearVehicle(location)
	local veh, distance = GetClosestVehicle(location)
	if distance <= 1 then
		for i = 1, #LocalVehicles do
			if LocalVehicles[i] ~= nil and LocalVehicles[i].entity == veh then
				LocalVehicles[i] = nil
			end
		end
		local driver = GetPedInVehicleSeat(veh, -1)
		if not DoesEntityExist(driver) or not IsPedAPlayer(driver) then
			NetworkRequestControlOfEntity(veh)
			local tmpModel = GetEntityModel(veh)
			SetModelAsNoLongerNeeded(tmpModel)
			Parking.Functions.DeteteParkedBlip(veh)
			DeleteEntity(veh)
		end
	end
end

function Parking.Functions.RemoveVehicles(vehicles)
	DeletingEntities = true
	for i = 1, #vehicles, 1 do
		local veh, distance = GetClosestVehicle(vehicles[i].location)
		if NetworkGetEntityIsLocal(veh) and distance < 1 then
			local driver = GetPedInVehicleSeat(veh, -1)
			if not DoesEntityExist(driver) or not IsPedAPlayer(driver) then
				Parking.Functions.DeteteParkedBlip(veh)
				local tmpModel = GetEntityModel(veh)
				SetModelAsNoLongerNeeded(tmpModel)
				DeleteEntity(veh)
				Wait(300)
			end
		end
	end
	LocalVehicles = {}
	Wait(1500)
	DeletingEntities = false
end

function Parking.Functions.UpdateVehicleStatus()
	for i = 1, #LocalVehicles do
		if type(LocalVehicles[i]) ~= 'nil' and type(LocalVehicles[i].entity) ~= 'nil' then
			if DoesEntityExist(LocalVehicles[i].entity) and type(LocalVehicles[i].onground) == 'nil' then
				if GetDistanceBetweenCoords(GetEntityCoords(LocalVehicles[i].entity), GetEntityCoords(GetPlayerPed(-1))) < 50.0 then
					SetEntityCoords(LocalVehicles[i].entity, LocalVehicles[i].location.x, LocalVehicles[i].location.y, LocalVehicles[i].location.z)
					SetVehicleOnGroundProperly(LocalVehicles[i].entity)
					LocalVehicles[i].onground = true
				end
			end
		end
	end
end

function Parking.Functions.DeteteParkedBlip(vehicle)
	local plate = GetPlate(vehicle)
	for k, v in pairs(LocalVehicles) do
		if v.entity == vehicle or Trim(v.plate) == Trim(plate) then
			RemoveBlip(v.blip)
			v.blip = nil
		end
	end
end

function Parking.Functions.DeleteLocalVehicle(vehicle)
	for i = 1, #LocalVehicles do
		if type(vehicle.plate) ~= 'nil' and type(LocalVehicles[i]) ~= 'nil' and type(LocalVehicles[i].plate) ~= 'nil' then
			if vehicle.plate == LocalVehicles[i].plate then
				NetworkRequestControlOfEntity(LocalVehicles[i].entity)
				local tmpModel = GetEntityModel(LocalVehicles[i].entity)
				Parking.Functions.DeteteParkedBlip(LocalVehicles[i].entity)
				SetModelAsNoLongerNeeded(tmpModel)
				DeleteEntity(LocalVehicles[i].entity)
				LocalVehicles[i] = nil
				tmpModel = nil
			end
		end
	end
end

function Parking.Functions.DeleteAllVehicles()
	if type(LocalVehicles) == 'table' and #LocalVehicles > 0 then
		for i = 1, #LocalVehicles, 1 do
			if LocalVehicles[i] then
				if LocalVehicles[i].entity ~= nil then
					if DoesEntityExist(LocalVehicles[i].entity) then
						DeleteEntity(LocalVehicles[i].entity)
						LocalVehicles[i].entity = nil
					end
				end
				if LocalVehicles[i].trailerEntity ~= nil then
					if DoesEntityExist(LocalVehicles[i].trailerEntity) then
						DeleteEntity(LocalVehicles[i].trailerEntity)
						LocalVehicles[i].trailerEntity = nil
					end
				end
			end
		end
		LocalVehicles = {}
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

function Parking.Functions.AllowToPark(coords)
	local isAllowd = false
	if Config.UseParkingLotsOnly then
		if Parking.Functions.IsCloseByParkingLot(coords) and not Parking.Functions.IsCloseByStationPump(coords) then isAllowd = true end
	elseif not Config.UseParkingLotsOnly then
		if not Parking.Functions.IsCloseByCoords(coords) and not Parking.Functions.IsCloseByStationPump(coords) then isAllowd = true end
	end
	return isAllowd
end

function Parking.Functions.CreateParkedBlip(data)
	local name = Config.Vehicles[GetHashKey(data.vehicle)].name or "unknow"
	local brand = Config.Vehicles[GetHashKey(data.vehicle)].brand or "unknow"
	local blip = AddBlipForCoord(data.location.x, data.location.y, data.location.z)
	SetBlipSprite(blip, 545)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, 0.6)
	SetBlipAsShortRange(blip, true)
	SetBlipColour(blip, 25)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(Lang:t('info.parked_blip', {model = name .. " " .. brand}))
	EndTextCommandSetBlipName(blip)
	return blip
end

function Parking.Functions.DeleteVehicleAtcoords(coords)
	local closestVehicle, closestDistance = GetClosestVehicle(coords)
	if closestVehicle ~= -1 and closestDistance <= 2.0 then
		DeleteEntity(closestVehicle)
		while DoesEntityExist(closestVehicle) do
			DeleteEntity(closestVehicle)
			Wait(50)
		end
	end
end

function Parking.Functions.LockDoors(entity, data)
	TriggerServerEvent('mh-parkingV2:server:SetVehLockState', VehToNet(entity), 2)
	SetVehicleDoorsLocked(entity, 2)
	if Config.VehicleDoorsUnlockedForOwners and PlayerData.citizenid == data.owner then
		TriggerServerEvent('mh-parkingV2:server:SetVehLockState', VehToNet(entity), 1)
		SetVehicleDoorsLocked(entity, 1)
	end
end

function Parking.Functions.Drive(vehicle)
	local entity = GetEntity(vehicle)
	if entity ~= nil then
		TriggerCallback("mh-parkingV2:server:DriveCar", function(callback)
			if callback.status then
				SetEntityVisible(PlayerPedId(), false, 0)
				Parking.Functions.DeteteParkedBlip(entity)
				DeleteVehicle(entity)
				DeleteVehicle(GetVehiclePedIsIn(GetPlayerPed(-1)))
				entity = nil
				Wait(500)
				Parking.Functions.DriveVehicle(callback)
				DisplayHelpText(callback.message)
			else
				DisplayHelpText(callback.message)
			end
			Wait(1000)
		end, vehicle)
	end
end

function Parking.Functions.Save(vehicle)
	local allowToPark = Parking.Functions.AllowToPark(GetEntityCoords(PlayerPedId()))
	if allowToPark then
		if DoesEntityExist(vehicle) then
			local canSave = true
			local vehPos = GetEntityCoords(vehicle)
			local vehHead = GetEntityHeading(vehicle)
			local vehPlate = GetPlate(vehicle)
			local trailerdata = nil
			if Config.ParkVehiclesWithTrailers then
				local hasTrailer, trailer = GetVehicleTrailerVehicle(vehicle)
				if hasTrailer then
					trailerdata = {
						hash = GetEntityModel(trailer),
						coords = GetEntityCoords(trailer),
						heading = GetEntityHeading(trailer),
						mods = GetVehicleProperties(trailer),
						load = trailerLoad[vehPlate]
					}
				end
			end
			TaskLeaveVehicle(PlayerPedId(), vehicle, 1)
			Wait(2500)
			if Config.OnlyAutoParkWhenEngineIsOff and GetIsVehicleEngineRunning(vehicle) then canSave = false end
			if canSave then
				Parking.Functions.BlinkVehiclelights(vehicle, true)
				TriggerCallback("mh-parkingV2:server:SaveCar", function(callback)
					if callback.status then
						TriggerServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', vehPlate)
						DeleteVehicle(vehicle)
						trailerLoad[vehPlate] = nil
						DisplayHelpText(callback.message)
					else
						FreezeEntityPosition(vehicle, false)
						DisplayHelpText(callback.message)
					end
				end, {
					mods = GetVehicleProperties(vehicle),
					fuel = exports[Config.FuelScript]:GetFuel(vehicle),
					plate = vehPlate,
					engine = GetVehicleEngineHealth(vehicle),
					body = GetVehicleBodyHealth(vehicle),
					street = GetStreetName(vehicle),
					steerangle = GetVehicleSteeringAngle(vehicle),
					location = { x = vehPos.x, y = vehPos.y, z = vehPos.z, h = vehHead },
					trailerdata = trailerdata,
				})
			elseif not canSave then
				SetVehicleEngineOn(vehicle, false, false, true)
			end
		end
	end
end

function Parking.Functions.DriveVehicle(data)
	SetEntityVisible(PlayerPedId(), false, 0)
	Parking.Functions.DeleteNearVehicle(vector3(data.location.x, data.location.y, data.location.z))
	LoadModel(data.mods["model"])
	local tempVeh = CreateVehicle(data.mods["model"], data.location.x, data.location.y, data.location.z, data.location.h, true)
	while not DoesEntityExist(tempVeh) do Wait(1) end
	SetVehicleProperties(tempVeh, data.mods)
	DoVehicleDamage(tempVeh, data.body, data.engine)
	exports[Config.FuelScript]:SetFuel(tempVeh, data.fuel)
	SetVehicleOnGroundProperly(tempVeh)
	SetVehRadioStation(tempVeh, 'OFF')
	SetVehicleDirtLevel(tempVeh, 0)
	TaskWarpPedIntoVehicle(GetPlayerPed(-1), tempVeh, -1)
	SetEntityVisible(PlayerPedId(), true, 0)
	FreezeEntityPosition(tempVeh, false)
	SetEntityCollision(tempVeh, true, true)
	if Config.ParkVehiclesWithTrailers then
		if data.trailerdata ~= nil then
			data.trailerEntity = Parking.Functions.SpawnTrailer(tempVeh, data)
			FreezeEntityPosition(data.trailerEntity, false)
		end
	end
end

function Parking.Functions.ConnectVehicleToTrailer(vehicle, trailer, data)
	local vehiclebone, trailerbone = GetVehicleAndTrailerBones(vehicle, trailer)
	SetEntityAsMissionEntity(vehicle, true, true)
	SetEntityAsMissionEntity(trailer, true, true)
	SetEntityVisible(trailer, false, 0)
	AttachEntityBoneToEntityBone(trailer, vehicle, trailerbone, vehiclebone, false, false)
	SetTrailerLegsRaised(trailer)
	SetVehicleOnGroundProperly(vehicle)
	local retval, groundZ = GetGroundZFor_3dCoord(data.location.x, data.location.y, data.location.z, false)
	if retval then SetEntityCoords(vehicle, data.location.x, data.location.y, groundZ - 1) end
	Wait(100)
	if IsEntityAttached(trailer) then
		FreezeEntityPosition(trailer, false)
		DetachEntity(trailer, true, true)
	end
	Wait(100)
	SetEntityVisible(vehicle, true, 0)
	SetEntityVisible(trailer, true, 0)
end

function Parking.Functions.LockAllParkedVehicles()
	Wait(15000)
	if isLoggedIn then
		if type(LocalVehicles) == 'table' and #LocalVehicles >= 1 then
			for i = 1, #LocalVehicles, 1 do
				if LocalVehicles[i] ~= nil and type(LocalVehicles[i]) == 'table' then
					if LocalVehicles[i].entity ~= nil and DoesEntityExist(LocalVehicles[i].entity) then
						FreezeEntityPosition(LocalVehicles[i].entity, true)
					end
					if LocalVehicles[i].trailerEntity ~= nil  and DoesEntityExist(LocalVehicles[i].trailerEntity)  then
						FreezeEntityPosition(LocalVehicles[i].trailerEntity, true)
					end
				end
			end
		end
	end
	Parking.Functions.LockAllParkedVehicles()
end

function Parking.Functions.SpawnTrailer(vehicle, data)
	local tempVeh = nil
	if Config.ParkVehiclesWithTrailers then
		local offset, posX, posY = -8.0, 0.0, 0.0
		local heading = GetEntityHeading(vehicle)
		local vehicleCoords = GetEntityCoords(vehicle)
		if Config.Trailers[data.trailerdata.hash] then
			if Config.Trailers[data.trailerdata.hash].offset ~= nil then
				if Config.Trailers[data.trailerdata.hash].offset.backwards ~= nil then
					offset = Config.Trailers[data.trailerdata.hash].offset.backwards
				end
				if Config.Trailers[data.trailerdata.hash].offset.heading ~= nil then
					heading = heading - Config.Trailers[data.trailerdata.hash].offset.heading
				end
				if Config.Trailers[data.trailerdata.hash].offset.posX ~= nil then
					posX = posX - Config.Trailers[data.trailerdata.hash].offset.posX
				end
			end
		end
		local trailerSpawnPos = GetOffsetFromEntityInWorldCoords(vehicle, posX, offset, 0.0)
		Parking.Functions.DeleteVehicleAtcoords(trailerSpawnPos)
		Wait(1000)
		LoadModel(data.trailerdata.hash)
		tempVeh = CreateVehicle(data.trailerdata.hash, trailerSpawnPos.x, trailerSpawnPos.y, vehicleCoords.z - 1.5, heading, true, false)
		while not DoesEntityExist(tempVeh) do Wait(1) end
		SetEntityAsMissionEntity(tempVeh, true, true)
		RequestCollisionAtCoord(trailerSpawnPos.x, trailerSpawnPos.y, trailerSpawnPos.z)
		SetVehicleOnGroundProperly(tempVeh)
		SetVehicleProperties(tempVeh, data.trailerdata.mods)
		SetVehicleDirtLevel(tempVeh, 0)
		TriggerCallback("mh-parkingV2:server:GetTrailerLoad", function(callback)
			if callback.status then
				if callback.load ~= nil then
					if GetEntityModel(tempVeh) == 2078290630 then -- Tr2 trailer
						if not trailerLoad[data.plate] then trailerLoad[data.plate] = {} end
						local trailer = Config.Trailers[GetEntityModel(tempVeh)]
						for l, load in pairs(callback.load) do
							for k, park in pairs(trailer.parklist) do
								if load.id == park.id then
									if not park.loaded and park.entity == nil then
										park.loaded = true
										trailerLoad[data.plate][#trailerLoad[data.plate] + 1] = load
										LoadModel(load.hash)
										local tempLoad = CreateVehicle(load.hash, park.coords.x, park.coords.y, park.coords.z, heading, true)
										while not DoesEntityExist(tempLoad) do Wait(1) end
										park.entity = tempLoad
										local vehRotation = GetEntityRotation(vehicle)
										AttachVehicleOnToTrailer(tempLoad, tempVeh, 0.0, 0.0, 0.0, park.coords.x + 0.0, park.coords.y + 0.0, park.coords.z + 0.05, vehRotation.x, vehRotation.y, 0.0, false)
										Wait(100)
										DetachEntity(tempLoad, true, true)
										Wait(1000)
										local vehRotation = GetEntityRotation(tempLoad)
										local localcoords = GetOffsetFromEntityGivenWorldCoords(tempVeh, GetEntityCoords(tempLoad))
										AttachVehicleOnToTrailer(tempLoad, tempVeh, 0.0, 0.0, 0.0, localcoords.x + 0.0, localcoords.y + 0.0, localcoords.z, vehRotation.x, vehRotation.y, 0.0, false)
										SetVehicleProperties(tempLoad, load.mods)
										exports[Config.FuelScript]:SetFuel(tempLoad, 100.0)
										SetEntityInvincible(tempLoad, true)
										SetVehRadioStation(tempLoad, 'OFF')
										SetVehicleDirtLevel(tempLoad, 0)
										TriggerEvent('vehiclekeys:client:SetOwner', GetPlate(tempLoad))
										Wait(100)
										break
									end
								end
							end
						end
					elseif GetEntityModel(tempVeh) == 524108981 then -- Boat trailer
						trailerLoad[data.plate] = callback.load
						LoadModel(callback.load.hash)
						local tempLoad = CreateVehicle(callback.load.hash, trailerSpawnPos.x, trailerSpawnPos.y, trailerSpawnPos.z, heading, true)
						while not DoesEntityExist(tempLoad) do Wait(1) end
						local x, y, z = 0.0, -1.0, 0.25
						if GetEntityModel(tempLoad) == -1030275036 or GetEntityModel(tempLoad) == 3678636260 or GetEntityModel(tempLoad) == 3983945033 then
							local localcoords = GetOffsetFromEntityGivenWorldCoords(trailer, GetEntityCoords(tempLoad))
							x, y, z  = localcoords.y - 0.0, localcoords.y - 1.0, localcoords.z - 0.25
						end
						vehRotation = GetEntityRotation(tempLoad)
						AttachEntityToEntity(tempLoad, tempVeh, 20, x, y, z, vehRotation.x, vehRotation.y, vehRotation.z, false, false, true, false, 20, true)
						SetVehicleProperties(tempLoad, callback.load.mods)
						exports[Config.FuelScript]:SetFuel(tempLoad, 100.0)
						SetEntityInvincible(tempLoad, true)
						SetVehRadioStation(tempLoad, 'OFF')
						SetVehicleDirtLevel(tempLoad, 0)
						TriggerEvent('vehiclekeys:client:SetOwner', data.plate)
					end
				end
			end
		end, {plate = data.plate})
		Parking.Functions.ConnectVehicleToTrailer(vehicle, tempVeh, data)
	end
	return tempVeh
end

function Parking.Functions.SpawnVehicles(vehicles)
	while DeletingEntities do Wait(1000) end
	for i = 1, #vehicles, 1 do
		Parking.Functions.DeleteLocalVehicle(vehicles[i].vehicle)
		Parking.Functions.DeleteNearVehicle(vec3(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z))
		Parking.Functions.DeleteVehicleAtcoords(vehicles[i].location)
		Wait(1000)
		LoadModel(vehicles[i].mods["model"])
		local tempVeh = CreateVehicle(vehicles[i].mods["model"], vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z, vehicles[i].location.h, true)
		while not DoesEntityExist(tempVeh) do Wait(1) end
		vehicles[i].entity = tempVeh
		SetEntityAsMissionEntity(tempVeh, true, true)
		SetVehicleNumberPlateText(tempVeh, vehicles[i].plate)
		SetVehicleProperties(tempVeh, vehicles[i].mods)
		SetVehicleEngineOn(tempVeh, false, false, true)
		RequestCollisionAtCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z)
		SetVehicleOnGroundProperly(tempVeh)
		SetVehicleSteeringAngle(tempVeh, vehicles[i].steerangle + 0.0)
		SetVehicleLivery(tempVeh, vehicles[i].mods.livery)
		DoVehicleDamage(tempVeh, vehicles[i].body, vehicles[i].engine)
		exports[Config.FuelScript]:SetFuel(tempVeh, vehicles[i].fuel)
		SetEntityInvincible(tempVeh, true)
		SetVehRadioStation(tempVeh, 'OFF')
		SetVehicleDirtLevel(tempVeh, 0)
		SetModelAsNoLongerNeeded(vehicles[i].mods["model"])
		Parking.Functions.LockDoors(tempVeh, vehicles[i])
		if PlayerData.citizenid == vehicles[i].owner then
			TriggerServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', vehicles[i].plate)
		end
		if Config.ParkVehiclesWithTrailers then
			if vehicles[i].trailerdata ~= nil then
				vehicles[i].trailerEntity = Parking.Functions.SpawnTrailer(tempVeh, vehicles[i])
			end
		end
		Wait(50)
		Parking.Functions.AddToTable(tempVeh, vehicles[i])
		tempVeh = nil
	end
end

function Parking.Functions.SpawnVehicle(vehicleData)
	while DeletingEntities do Wait(500) end
	Parking.Functions.DeleteLocalVehicle(vehicleData.vehicle)
	Parking.Functions.DeleteNearVehicle(vec3(vehicleData.location.x, vehicleData.location.y, vehicleData.location.z))
	Parking.Functions.DeleteVehicleAtcoords(vehicleData.location)
	Wait(1000)
	LoadModel(vehicleData.mods["model"])
	local tempVeh = CreateVehicle(vehicleData.mods["model"], vehicleData.location.x, vehicleData.location.y, vehicleData.location.z, vehicleData.location.h, true)
	while not DoesEntityExist(tempVeh) do Wait(1) end
	vehicleData.entity = tempVeh
	SetEntityAsMissionEntity(tempVeh, true, true)
	SetVehicleNumberPlateText(tempVeh, vehicleData.plate)
	SetVehicleProperties(tempVeh, vehicleData.mods)
	SetVehicleEngineOn(tempVeh, false, false, true)
	RequestCollisionAtCoord(vehicleData.location.x, vehicleData.location.y, vehicleData.location.z)
	SetVehicleOnGroundProperly(tempVeh)
	SetVehicleSteeringAngle(tempVeh, vehicleData.steerangle + 0.0)
	SetEntityInvincible(tempVeh, true)
	DoVehicleDamage(tempVeh, vehicleData.body, vehicleData.engine)
	SetVehicleLivery(tempVeh, vehicleData.mods.livery)
	SetVehRadioStation(tempVeh, 'OFF')
	SetVehicleDirtLevel(tempVeh, 0)
	exports[Config.FuelScript]:SetFuel(tempVeh, vehicleData.fuel)
	SetModelAsNoLongerNeeded(vehicleData.mods["model"])
	Parking.Functions.LockDoors(tempVeh, vehicleData)
	if PlayerData.citizenid == vehicleData.owner then
		TriggerServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', vehicleData.plate)
	end
	if Config.ParkVehiclesWithTrailers then
		if vehicleData.trailerdata ~= nil then
			vehicleData.trailerEntity = Parking.Functions.SpawnTrailer(tempVeh, vehicleData)
		end
	end
	Wait(100)
	Parking.Functions.AddToTable(tempVeh, vehicleData)
	tempVeh = nil
end

function Parking.Functions.SpawnVehicleChecker()
	while true do
		Wait(1000)
		if isLoggedIn then
			local inParking = true
			if inParking then
				if not SpawnedVehicles then
					Parking.Functions.RemoveVehicles(GlobalVehicles)
					while DeletingEntities do Wait(100) end
					TriggerServerEvent("mh-parkingV2:server:RefreshVehicles")
					SpawnedVehicles = true
					Wait(2000)
				end
				Parking.Functions.UpdateVehicleStatus()
			else
				if SpawnedVehicles then
					Parking.Functions.RemoveVehicles(GlobalVehicles)
					SpawnedVehicles = false
				end
			end
		end
	end
end

function Parking.Functions.DisplayVehicleOwnerText()
	while true do
		Wait(0)
		if isLoggedIn and displayOwnerText then
			local fd = true
			local playerCoords = GetEntityCoords(GetPlayerPed(-1))
			if fd then
				fd = false
				for k, v in pairs(LocalVehicles) do
					if GetDistance(playerCoords, v.location) < Config.VehicleOwnerTextDisplayDistance then
						local owner, plate, model, brand = v.fullname, v.plate, "", ""
						for k, vehicle in pairs(Config.Vehicles) do
							if vehicle.model:lower() == vehicle.model:lower() then
								model, brand = vehicle.name, vehicle.brand
								break
							end
						end
						if model ~= nil and brand ~= nil then
							Draw3DText(v.location.x, v.location.y, v.location.z, Lang:t('info.model',{model = model}).. '\n' .. Lang:t('info.brand',{brand = brand}).. '\n' .. Lang:t('info.plate',{plate = plate}).. '\n' .. Lang:t('info.owner',{owner = owner}) , 0, 0.04, 0.04)
							fd = true
						end
					end
				end
			else
				Wait(100)
			end
		end
	end
end

function Parking.Functions.CheckSteeringAngle()
	local angle = 0.0
	local speed = 0.0
	while true do
		Wait(0)
		if isLoggedIn then
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
end

function Parking.Functions.CreateOwnerVehicleBlip(data)
	for i = 1, #LocalVehicles do
		if LocalVehicles[i] and LocalVehicles[i].plate ~= nil and Trim(LocalVehicles[i].plate) == Trim(data.plate) then
			LocalVehicles[i].blip = Parking.Functions.CreateParkedBlip(data)
			break
		end
	end
end

function Parking.Functions.OnJoin()
	PlayerData = GetPlayerData()
	isLoggedIn = true
	Wait(5000)
	Parking.Functions.LockAllParkedVehicles()
end

function Parking.Functions.RefreshVehicles(vehicles)
	GlobalVehicles = vehicles
	Parking.Functions.RemoveVehicles(vehicles)
	Wait(1000)
	Parking.Functions.SpawnVehicles(vehicles)
end

function Parking.Functions.AddVehicle(vehicle, playerId)
	if playerId == GetPlayerServerId(PlayerId()) then DeleteEntity(GetVehiclePedIsIn(GetPlayerPed(-1), false)) end
	Parking.Functions.SpawnVehicle(vehicle)
end

function Parking.Functions.GetVehicleMenu()
	TriggerCallback("mh-parkingV2:server:GetVehicles", function(vehicles)
		if #vehicles >= 1 then
			local options = {}
			for k, v in pairs(vehicles) do
				if v.state == 3 then
					local coords = json.decode(v.location)
					options[#options + 1] = {
						title = FirstToUpper(v.vehicle) .. " " .. v.plate .. " is parked",
						description = Lang:t('info.steet', {steet = v.steet}) .. '\n'.. Lang:t('info.fuel', {fuel = v.fuel}) .. '\n'.. Lang:t('info.engine', {engine = v.engine}) .. '\n'.. Lang:t('info.body', {body = v.body}) .. '\n'..Lang:t('info.click_to_set_waypoint'),
						arrow = false,
						onSelect = function()
							Parking.Functions.SetVehicleWaypoit(coords)
						end
					}
					num = num + 1
				end
			end
			options[#options + 1] = {title = Lang:t('info.close'), icon = "fa-solid fa-stop", description = '', arrow = false, onSelect = function() end}
			lib.registerContext({id = 'parkMenu', title = "MH Parking V2", icon = "fa-solid fa-warehouse", options = options})
			lib.showContext('parkMenu')
		else
			Notify(Lang:t('info.no_vehicles_parked'), "error", 5000)
		end
	end)
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

function Parking.Functions.RadialMenu()
	if Config.Framework == 'qb' then
		RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function()
			if parkMenu ~= nil then exports['qb-radialmenu']:RemoveOption(parkMenu) parkMenu = nil end
			parkMenu = exports['qb-radialmenu']:AddOption({id = 'park_vehicles_menu', title = Lang:t('info.park_menu'), icon = "square-parking", type = 'client', event = "mh-parkingV2:client:GetVehicleMenu", shouldClose = true}, parkMenu)
		end)
	elseif Config.Framework == 'esx' then
		lib.addRadialItem({{id = 'park_vehicles_menu', label = Lang:t('info.park_menu'), icon = 'square-parking', onSelect = function() TriggerEvent("mh-parkingV2:client:GetVehicleMenu") end}})
	end
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

function Parking.Functions.CreateBlips()
	if Config.UseUnableParkingBlips then
		for k, zone in pairs(Config.NoParkingLocations) do
			Parking.Functions.CreateBlipCircle(zone.coords, Lang:t('info.unable_to_park'), zone.radius, zone.color, zone.sprite)
		end
	end
	if Config.UseParkingLotsOnly then
		for k, zone in pairs(Config.AllowedParkingLots) do
			if Config.UseParkingLotsBlips then
				Parking.Functions.CreateBlipCircle(zone.coords, Lang:t('info.parking_lot'), zone.radius, zone.color, zone.sprite)
			end
		end
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
            TriggerServerEvent('mh-parkingV2:server:EnteredVehicle', currentVehicle, currentSeat, name, netId)
        end
    elseif isInVehicle then
        if not IsPedInAnyVehicle(ped, false) or IsPlayerDead(PlayerId()) then
            local name = GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle))
            local netId = VehToNet(currentVehicle)
			currentSeat = GetPedVehicleSeat(ped)
            TriggerServerEvent('mh-parkingV2:server:LeftVehicle', currentVehicle, currentSeat, name, netId)
            isInVehicle = false
            currentVehicle = 0
            currentSeat = 0
        end
    end
end

function Parking.Functions.AutoPark(driver)
    if isLoggedIn then
        local player = GetPlayerServerId(PlayerId())
		if player == driver then
			local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
			if vehicle ~= 0 and DoesEntityExist(vehicle) then
				Parking.Functions.Save(vehicle)
				isInVehicle = false
				currentVehicle = 0
				currentSeat = 0
			end
        elseif player ~= driver then
            TaskLeaveVehicle(PlayerPedId(), vehicle, 1)
        end
    end
end

function Parking.Functions.AutoDrive(driver)
    if isLoggedIn then
        local player = GetPlayerServerId(PlayerId())
        if player == driver then
			while not IsPedInAnyVehicle(PlayerPedId(), false) do Wait(5) end
			local storedVehicle = Parking.Functions.GetPedInStoredCar(PlayerPedId())
			if storedVehicle ~= false then Parking.Functions.Drive(storedVehicle) end
		end
    end
end

function Parking.Functions.KeepEngineRunning()
    if IsPedInAnyVehicle(PlayerPedId(), false) and IsControlPressed(2, 75) and not IsEntityDead(PlayerPedId()) then
        SetVehicleEngineOn(GetVehiclePedIsIn(PlayerPedId(), false), true, true, true)
    end
end

function LockVehiclesOnTrailer(plate, state)
	for i = 1, #trailerLoad[plate] do
		if trailerLoad[plate][i] then
			if trailerLoad[plate][i].entity then
				if state then
					local vehRotation = GetEntityRotation(trailerLoad[plate][i].entity)
					local localcoords = GetOffsetFromEntityGivenWorldCoords(trailer, GetEntityCoords(trailerLoad[plate][i].entity))
					AttachVehicleOnToTrailer(trailerLoad[plate][i].entity, trailer, 0.0, 0.0, 0.0, localcoords.x, localcoords.y, localcoords.z, vehRotation.x, vehRotation.y, 0.0, false)
				else
					DetachEntity(trailerLoad[plate][i].entity, true, true)
				end
				Wait(100)
			end
		end
	end
end

function Parking.Functions.GetIn(entity)
    TaskWarpPedIntoVehicle(PlayerPedId(), entity, -1)
    FreezeEntityPosition(entity, false)
    SetVehicleHandbrake(entity, false)
    DetachEntity(entity, true, true)
    SetVehicleEngineOn(entity, true, true)
	local plate = GetPlate(entity)
	Parking.Functions.RemoveVehicleFromTrailer(plate)
end

function Parking.Functions.AttachedToTrailer()
	while true do
        local sleep = 1000
        if isLoggedIn then
			local hasTrailer, trailer = GetVehicleTrailerVehicle(currentVehicle)
			if hasTrailer then
				local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
				if vehicle ~= -1 and trailer ~= vehicle and trailer ~= currentVehicle then
					sleep = 0
					if IsEntityTouchingEntity(vehicle, trailer) then DisplayHelpText(Lang:t('info.press_to_attach')) end
					if GetEntityModel(trailer) == 2078290630 then
						if IsControlJustPressed(0, Config.ParkingButton) then Parking.Functions.AddVehicleOnTrailer(vehicle, trailer) end
					elseif GetEntityModel(trailer) == 524108981 then
						if IsControlJustPressed(0, Config.ParkingButton) then Parking.Functions.AddBoatToTrailer(vehicle, trailer) end
					end
				end
			end
        end
        Wait(sleep)
    end
end

function Parking.Functions.RemoveVehicleFromTrailer(vehiclePlate)
	local truckPlate = GetPlate(currentTruck)
	for i = 1, #trailerLoad[truckPlate] do
		if trailerLoad[truckPlate][i] then
			if trailerLoad[truckPlate][i].plate == vehiclePlate then
				trailerLoad[truckPlate][i] = nil
				break
			end
		end
	end
end

function GetTrailerLocalPosNumber(trailer, coords)
	local number = -1
	for k, v in pairs(Config.Trailers[GetEntityModel(trailer)].parklist) do
		if #(v.coords - coords) < 1 then
			number = k
			break
		end
	end
	return number
end

function Parking.Functions.AddVehicleOnTrailer(vehicle, trailer)
    if IsEntityTouchingEntity(trailer, vehicle) then
        if not IsVehicleAttachedToTrailer(vehicle) then
			if GetEntityModel(trailer) == 2078290630 then -- Tr2 trailer
				SetVehicleEngineOn(vehicle, false, false, true)
				local truck = GetEntityAttachedTo(trailer)
				local plate = GetPlate(truck)
				local vehRotation = GetEntityRotation(vehicle)
				local localcoords = GetOffsetFromEntityGivenWorldCoords(trailer, GetEntityCoords(vehicle))
				AttachVehicleOnToTrailer(vehicle, trailer, 0.0, 0.0, 0.0, localcoords.x, localcoords.y, localcoords.z, vehRotation.x, vehRotation.y, 0.0, false)
				if not trailerLoad[plate] then trailerLoad[plate] = {} end
				local number = GetTrailerLocalPosNumber(trailer, localcoords)
				trailerLoad[plate][#trailerLoad[plate] + 1] = {
					id = number,
					entity = vehicle,
					coords = localcoords,
					hash = GetEntityModel(vehicle),
					mods = GetVehicleProperties(vehicle),
					plate = GetPlate(vehicle),
				}
				SetEntityCanBeDamaged(vehicle, false)
				LockVehiclesOnTrailer(plate, true)
			end
        else
            Notify(Lang:t('notify.already_on_trailer'))
        end
    end
end

function Parking.Functions.AddBoatToTrailer(boat, trailer)
    if IsEntityTouchingEntity(trailer, boat) then
        if not IsVehicleAttachedToTrailer(boat) then
            if GetEntityModel(trailer) == 524108981 then -- (boattrailer)
				if Config.TrailerBoats[GetEntityModel(boat)] then
					local x, y, z = 0.0, -1.0, 0.25
					if GetEntityModel(tempLoad) == -1030275036 or GetEntityModel(tempLoad) == 3678636260 or GetEntityModel(tempLoad) == 3983945033 then
						local localcoords = GetOffsetFromEntityGivenWorldCoords(trailer, GetEntityCoords(tempLoad))
						x, y, z  = localcoords.y - 0.0, localcoords.y - 1.0, localcoords.z - 0.25
					end
					vehRotation = GetEntityRotation(tempLoad)
					AttachEntityToEntity(tempLoad, tempVeh, 20, x, y, z, vehRotation.x, vehRotation.y, vehRotation.z, false, false, true, false, 20, true)
					trailerLoad[plate] = {hash = GetEntityModel(boat), mods = GetVehicleProperties(boat)}
				end
			end
            SetEntityCanBeDamaged(boat, false)
			SetVehicleEngineOn(boat, false, false, true)
			TaskLeaveVehicle(PlayerPedId(), boat, 1)
			isInVehicle = false
			currentVehicle = 0
			currentSeat = 0
        end
    end
end

function Parking.Functions.AttachedToTrailer()
	while true do
        local sleep = 1000
        if isLoggedIn then
			local hasTrailer, trailer = GetVehicleTrailerVehicle(currentTruck)
			if hasTrailer then
				local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
				if vehicle ~= -1 and trailer ~= vehicle and trailer ~= currentTruck then
					sleep = 0
					if IsEntityTouchingEntity(trailer, vehicle) then DisplayHelpText(Lang:t('info.press_to_attach')) end
					if not IsVehicleAttachedToTrailer(vehicle) then
						if IsControlJustPressed(0, Config.ParkingButton) then
							if GetEntityModel(trailer) == 524108981 then -- boat trailer
								Parking.Functions.AddBoatToTrailer(vehicle, trailer)
							elseif GetEntityModel(trailer) == 2078290630 then -- tr2 trailer
								Parking.Functions.AddVehicleOnTrailer(vehicle, trailer)
							end
						end
					end
				end
			end
        end
        Wait(sleep)
    end
end

local disableCollisionVehicles = {}
function Parking.Functions.DisableParkedVehiclesCollision()
	while true do
		Wait(0)
		if isLoggedIn and Config.DisableParkedVehiclesCollision then
			local playerCoords = GetEntityCoords(GetPlayerPed(-1))
			local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
			if vehicle ~= nil and vehicle ~= 0 then
				if (GetPedInVehicleSeat(vehicle, -1) == GetPlayerPed(-1)) then
					for k, v in pairs(LocalVehicles) do
						if GetDistance(playerCoords, v.location) < 5.0 then
							SetEntityCollision(v.entity, false, false)
							FreezeEntityPosition(v.entity, true)
							disableCollisionVehicles[#disableCollisionVehicles + 1] = { vehicle = v.entity, location = v.location}
						elseif GetDistance(playerCoords, v.location) > 5.0 then
							SetEntityCollision(v.entity, true, true)
						end
					end
				end
			else
				if #disableCollisionVehicles > 0 then
					for	k, v in pairs(disableCollisionVehicles) do
						if GetDistance(playerCoords, v.location) > 5.0 then
							SetEntityCollision(v.vehicle, true, true)
						end
					end
					disableCollisionVehicles = {}
				end
			end
		end
	end
end

function Parking.Functions.LoadTarget()
	for k, v in pairs(Config.TrailerBoats) do
        exports['qb-target']:AddTargetModel(v.model, {
			options = {{
				type = "client",
				event = "mh-parkingV2:client:GetInVehicle",
				icon = "fas fa-car",
				label = Lang:t('info.get_in_vehicle'),
				action = function(entity)
					Parking.Functions.GetIn(entity)
				end,
				canInteract = function(entity, distance, data)
					if currentTrailer == -1 then return false end
					return true
				end
			}},
			distance = 15.0
		})
    end
	for k, v in pairs(Config.Trailers) do
		exports['qb-target']:AddTargetModel(v.model, {
			options = {
			{
				type = "client",
				event = "",
				icon = "fas fa-car",
				label = 'Ramp Down',
				action = function(entity)
					SetVehicleDoorOpen(entity, 5, false)
					currentTrailer = entity
					isRampDown = true
				end,
				canInteract = function(entity, distance, data)
					if isRampDown then return false end
					return true
				end
			}, {
				type = "client",
				event = "",
				icon = "fas fa-car",
				label = 'Ramp Up',
				action = function(entity)
					SetVehicleDoorShut(entity, 5, true)
					currentTrailer = entity
					isRampDown = false
				end,
				canInteract = function(entity, distance, data)
					if not isRampDown then return false end
					return true
				end
			},
			{
				type = "client",
				event = "mh-parkingV2:client:togglePlatform",
				icon = "fas fa-car",
				label = "Platform Up",
				action = function(entity)
					currentTrailer = entity
					SetVehicleDoorShut(entity, 4, false)
					isPlatformDown = false
				end,
				canInteract = function(entity, distance, data)
					if isRampDown then return false end
					if not isPlatformDown then return false end
					return true
				end
			}, {
				type = "client",
				event = "mh-parkingV2:client:togglePlatform",
				icon = "fas fa-car",
				label = 'Platform Down',
				action = function(entity)
					currentTrailer = entity
					isPlatformDown = true
					SetVehicleDoorOpen(entity, 4, false)
				end,
				canInteract = function(entity, distance, data)
					if not isRampDown then return false end
					if isPlatformDown then return false end
					return true
				end
			}},
			distance = 5.0
		})
	end
	for k, v in pairs(Config.Vehicles) do
        exports['qb-target']:AddTargetModel(v.model, {
			options = {{
				type = "client",
				event = "",
				icon = "fas fa-car",
				label = Lang:t('info.get_in_vehicle'),
				action = function(entity)
					Parking.Functions.GetIn(entity)
				end,
				canInteract = function(entity, distance, data)
					if currentTrailer == -1 then return false end
					return true
				end
			},{
				type = "client",
				event = "",
				icon = "fas fa-car",
				label = Lang:t('info.select_vehicle'),
				action = function(entity)
					currentTruck = entity
				end,
				canInteract = function(entity, distance, data)
					return true
				end
			}},
			distance = 15.0
		})
    end
end