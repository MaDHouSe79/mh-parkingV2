--[[ ===================================================== ]] --
--[[          MH Realistic Parking V2 by MaDHouSe79        ]] --
--[[ ===================================================== ]] --
Parking = {}
Parking.Functions = {}
diableParkedBlips = {}
parkMenu = nil

function Parking.Functions.GetParkeddCar(vehicle)
    local findVehicle = false
    for i = 1, #LocalVehicles do
        if LocalVehicles[i].entity and LocalVehicles[i].entity == vehicle then
            findVehicle = LocalVehicles[i]
            break
        end
    end
    return findVehicle
end

function Parking.Functions.CreateTargetEntityMenu(entity)
    exports['qb-target']:AddTargetEntity(entity, {
        options = {
            {
                name = "car",
                type = "client",
                event = "mh-parkingV2:client:Unparking",
                icon = "fas fa-car",
                label = "Unpark Vehicle"
            }
        },
        distance = Config.InteractDistance
    })
end

function Parking.Functions.TargetDrive()
	local vehicle, distance = GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if distance <= Config.InteractDistance then
        Parking.Functions.Drive(Parking.Functions.GetParkeddCar(vehicle), false)
    else
        Notify("to far from vehicle", "error", 2000)
    end
end

function Parking.Functions.TargetPark()
    local vehicle, distance = GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if distance <= Config.InteractDistance then
        Parking.Functions.Save(vehicle)
    else
        Notify(Lang:t("system.to_far_from_vehicle"), "error", 2000)
    end
end

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
        FreezeEntityPosition(vehicle, true)
        SetEntityInvincible(vehicle, true)
    else
        FreezeEntityPosition(vehicle, false)
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

function Parking.Functions.DriveVehicle(data)
	SetEntityVisible(PlayerPedId(), false, 0)
	Parking.Functions.DeleteNearVehicle(vector3(data.location.x, data.location.y, data.location.z))
	LoadModel(data.mods["model"])
	local tempVeh = CreateVehicle(data.mods["model"], data.location.x, data.location.y, data.location.z, data.location.h, true)
	while not DoesEntityExist(tempVeh) do Citizen.Wait(500) end
	SetVehicleProperties(tempVeh, data.mods)
	DoVehicleDamage(tempVeh, data.body, data.engine)
	exports[Config.FuelScript]:SetFuel(tempVeh, data.fuel)
	SetVehicleOnGroundProperly(tempVeh)
	SetVehRadioStation(tempVeh, 'OFF')
    SetVehicleDirtLevel(tempVeh, 0)
	TaskWarpPedIntoVehicle(GetPlayerPed(-1), tempVeh, -1)
	SetEntityVisible(PlayerPedId(), true, 0)
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
				Citizen.Wait(300)
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
            if LocalVehicles[i].entity ~= nil then
                if DoesEntityExist(LocalVehicles[i].entity) then
					DeleteEntity(LocalVehicles[i].trailerEntity)
                    DeleteEntity(LocalVehicles[i].entity)
                    LocalVehicles[i].entity = nil
					LocalVehicles[i].trailerEntity = nil
                end
            end
        end
		LocalVehicles = {}
    end
end

function Parking.Functions.Drive(vehicle)
	TriggerCallback("mh-parkingV2:server:DriveCar", function(callback)
		if callback.status then
			SetEntityVisible(PlayerPedId(), false, 0)
			Parking.Functions.DeteteParkedBlip(vehicle.entity)
			DeleteVehicle(vehicle.entity)
			DeleteVehicle(GetVehiclePedIsIn(GetPlayerPed(-1)))
			vehicle = nil
			Wait(500)
			Parking.Functions.DriveVehicle(callback)
			DisplayHelpText(callback.message)
		else
			DisplayHelpText(callback.message)
		end
		Wait(1000)
	end, vehicle)
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
					local hashkey = GetEntityModel(trailer)
					local trailerProps = GetVehicleProperties(trailer)
					if Config.Trailers[hashkey] then
						trailerdata = {hash = hashkey, coords = GetEntityCoords(trailer), heading = GetEntityHeading(trailer), mods = trailerProps}
					end
				end
			end
			TaskLeaveVehicle(PlayerPedId(), vehicle, 1)
			Wait(2500)
			Parking.Functions.BlinkVehiclelights(vehicle, true)
			TriggerCallback("mh-parkingV2:server:SaveCar", function(callback)
				if callback.status then
					TriggerServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', vehPlate)
					DeleteVehicle(vehicle)
					DisplayHelpText(callback.message)
				else
					DisplayHelpText(callback.message)
				end
			end, {
				mods = GetVehicleProperties(vehicle),
				fuel = exports[Config.FuelScript]:GetFuel(vehicle),
				engine = GetVehicleEngineHealth(vehicle),
				body = GetVehicleBodyHealth(vehicle),
				street = GetStreetName(vehicle),
				steerangle = GetVehicleSteeringAngle(vehicle),
				location = {x = vehPos.x, y = vehPos.y, z = vehPos.z, h = vehHead},
				trailerdata = trailerdata,
			})
		end
	end
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
    AddTextComponentSubstringPlayerName("Parked: "..name .." "..brand)
    EndTextCommandSetBlipName(blip)
    return blip
end

function Parking.Functions.DeleteVehicleAtcoords(coords)
    local closestVehicle, closestDistance = GetClosestVehicle(coords)
    if closestVehicle ~= -1 and closestDistance <= 1.5 then
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
					heading -= Config.Trailers[data.trailerdata.hash].offset.heading
				end
				if Config.Trailers[data.trailerdata.hash].offset.posX ~= nil then
					posX -= Config.Trailers[data.trailerdata.hash].offset.posX
				end
			end
		end
		local trailerSpawnPos = GetOffsetFromEntityInWorldCoords(vehicle, posX, offset, 1.0)
		Parking.Functions.DeleteVehicleAtcoords(coords)
		Wait(500)
		LoadModel(data.trailerdata.hash)
		tempVeh = CreateVehicle(data.trailerdata.hash, trailerSpawnPos.x, trailerSpawnPos.y, vehicleCoords.z, heading, true)
		while not DoesEntityExist(tempVeh) do Wait(500) end
		SetEntityAsMissionEntity(tempVeh, true, true)
		local plate = GetPlate(vehicle)
		SetVehicleNumberPlateText(tempVeh, plate.."1")
		RequestCollisionAtCoord(trailerSpawnPos.x, trailerSpawnPos.y, trailerSpawnPos.y)
		SetVehicleOnGroundProperly(tempVeh)
		SetVehicleProperties(tempVeh, data.trailerdata.mods)
		SetVehicleDirtLevel(tempVeh, 0)
		NetworkFadeInEntity(tempVeh, true)
		while NetworkIsEntityFading(tempVeh) do Citizen.Wait(50) end
		Wait(2000)
		if not IsEntityPositionFrozen(tempVeh) then FreezeEntityPosition(tempVeh, true) end
		if not IsEntityPositionFrozen(vehicle) then FreezeEntityPosition(vehicle, true) end
	end
    return tempVeh
end

function Parking.Functions.SpawnVehicles(vehicles)
	while DeletingEntities do Citizen.Wait(100) end
	for i = 1, #vehicles, 1 do
		Parking.Functions.DeleteLocalVehicle(vehicles[i].vehicle)
		Parking.Functions.DeleteNearVehicle(vec3(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z))
		Parking.Functions.DeleteVehicleAtcoords(vehicles[i].location)
		Wait(500)
		LoadModel(vehicles[i].mods["model"])
		local tempVeh = CreateVehicle(vehicles[i].mods["model"], vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z, vehicles[i].location.h, true)
		while not DoesEntityExist(tempVeh) do Citizen.Wait(500) end
		SetEntityAsMissionEntity(tempVeh, true, true)
		SetVehicleNumberPlateText(veh, vehicles[i].plate)
		SetVehicleEngineOn(tempVeh, false, false, true)
		SetVehicleProperties(tempVeh, vehicles[i].mods)
		RequestCollisionAtCoord(vehicles[i].location.x, vehicles[i].location.y, vehicles[i].location.z)
		SetVehicleOnGroundProperly(tempVeh)
		SetModelAsNoLongerNeeded(vehicles[i].mods["model"])
		SetEntityInvincible(tempVeh, true)
		SetVehicleLivery(tempVeh, vehicles[i].mods.livery)
		DoVehicleDamage(tempVeh, vehicles[i].body, vehicles[i].engine)
		exports[Config.FuelScript]:SetFuel(tempVeh, vehicles[i].fuel)
		SetVehRadioStation(tempVeh, 'OFF')
		SetVehicleDirtLevel(tempVeh, 0)
		Parking.Functions.LockDoors(tempVeh, vehicles[i])
		NetworkFadeInEntity(tempVeh, true)
		while NetworkIsEntityFading(tempVeh) do Citizen.Wait(50) end
		Wait(500)
		if Config.ParkVehiclesWithTrailers then
			if vehicles[i].trailerdata ~= nil then
				vehicles[i].trailerEntity = Parking.Functions.SpawnTrailer(tempVeh, vehicles[i])
			else
				if not IsEntityPositionFrozen(tempVeh) then FreezeEntityPosition(tempVeh, true) end
			end
		end
		Wait(50)
		Parking.Functions.AddToTable(tempVeh, vehicles[i])
		Wait(50)

		if Config.ParkVehiclesWithTrailers then
			local vehiclebone = -1
			if GetEntityBoneIndexByName(vehicle, 'attach_female') ~= -1 then
				vehiclebone = GetEntityBoneIndexByName(vehicle, 'attach_female')
			elseif GetEntityBoneIndexByName(vehicle, 'attach_male') then
				vehiclebone = GetEntityBoneIndexByName(vehicle, 'attach_male')
			end

			local trailerbone = -1
			if GetEntityBoneIndexByName(vehicles[i].trailerEntity, 'attach_female') ~= -1 then
				trailerbone = GetEntityBoneIndexByName(vehicle, 'attach_female')
			elseif GetEntityBoneIndexByName(vehicles[i].trailerEntity, 'attach_male') then
				trailerbone = GetEntityBoneIndexByName(vehicles[i].trailerEntity, 'attach_male')
			end
			if vehiclebone ~= -1 and trailerbone ~= -1 then
				AttachEntityBoneToEntityBone(vehicle, vehicles[i].trailerEntity, vehiclebone, trailerbone, false, false)
				AttachEntityToEntity(trailerbone, vehiclebone, 1, 0.0, -1.0, 0.25, 0.0, 0.0, 0.0, false, false, true, false, 20, true)
				SetTrailerLegsRaised(vehicles[i].trailerEntity)
			end
		end



		SetVehicleSteeringAngle(tempVeh, vehicles[i].steerangle + 0.0)
		if PlayerData.citizenid == vehicles[i].owner then
			Parking.Functions.CreateTargetEntityMenu(tempVeh)
			TriggerServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', vehicles[i].plate)
		end
	end
end

function Parking.Functions.SpawnVehicle(vehicleData)
	while DeletingEntities do Citizen.Wait(100) end
	Parking.Functions.DeleteLocalVehicle(vehicleData.vehicle)
	Parking.Functions.DeleteNearVehicle(vec3(vehicleData.location.x, vehicleData.location.y, vehicleData.location.z))
	Parking.Functions.DeleteVehicleAtcoords(vehicleData.location)
	Wait(50)
	LoadModel(vehicleData.mods["model"])
	local tempVeh = CreateVehicle(vehicleData.mods["model"], vehicleData.location.x, vehicleData.location.y, vehicleData.location.z, vehicleData.location.h, true)
	while not DoesEntityExist(tempVeh) do Citizen.Wait(500) end
	SetEntityAsMissionEntity(tempVeh, true, true)
	SetVehicleEngineOn(tempVeh, false, false, true)
	SetVehicleProperties(tempVeh, vehicleData.mods)
	SetVehicleNumberPlateText(veh, vehicleData.plate)
	RequestCollisionAtCoord(vehicleData.location.x, vehicleData.location.y, vehicleData.location.z)
	SetVehicleOnGroundProperly(tempVeh)
	SetModelAsNoLongerNeeded(vehicleData.mods["model"])
	SetEntityInvincible(tempVeh, true)
	DoVehicleDamage(tempVeh, vehicleData.body, vehicleData.engine)
	exports[Config.FuelScript]:SetFuel(tempVeh, vehicleData.fuel)
	SetVehicleLivery(tempVeh, vehicleData.mods.livery)
	SetVehRadioStation(tempVeh, 'OFF')
	SetVehicleDirtLevel(tempVeh, 0)
	Parking.Functions.LockDoors(tempVeh, vehicleData)
	NetworkFadeInEntity(tempVeh, true)
	while NetworkIsEntityFading(tempVeh) do Citizen.Wait(50) end
	Wait(500)
	if Config.ParkVehiclesWithTrailers then
		if vehicleData.trailerdata ~= nil then
			vehicleData.trailerEntity = Parking.Functions.SpawnTrailer(tempVeh, vehicleData)
		else
			if not IsEntityPositionFrozen(tempVeh) then FreezeEntityPosition(tempVeh, true) end
		end
	end
	Wait(50)
	Parking.Functions.AddToTable(tempVeh, vehicleData)
	Wait(50)


	if Config.ParkVehiclesWithTrailers then
		local vehiclebone = -1
		if GetEntityBoneIndexByName(vehicle, 'attach_female') ~= -1 then
			vehiclebone = GetEntityBoneIndexByName(vehicle, 'attach_female')
		elseif GetEntityBoneIndexByName(vehicle, 'attach_male') then
			vehiclebone = GetEntityBoneIndexByName(vehicle, 'attach_male')
		end

		local trailerbone = -1
		if GetEntityBoneIndexByName(vehicles[i].trailerEntity, 'attach_female') ~= -1 then
			trailerbone = GetEntityBoneIndexByName(vehicle, 'attach_female')
		elseif GetEntityBoneIndexByName(vehicles[i].trailerEntity, 'attach_male') then
			trailerbone = GetEntityBoneIndexByName(vehicles[i].trailerEntity, 'attach_male')
		end
		if vehiclebone ~= -1 and trailerbone ~= -1 then
			AttachEntityBoneToEntityBone(vehicle, vehicles[i].trailerEntity, vehiclebone, trailerbone, false, false)
			AttachEntityToEntity(trailerbone, vehiclebone, 1, 0.0, -1.0, 0.25, 0.0, 0.0, 0.0, false, false, true, false, 20, true)
			SetTrailerLegsRaised(vehicles[i].trailerEntity)
		end
	end


	SetVehicleSteeringAngle(tempVeh, vehicleData.steerangle + 0.0)
	if PlayerData.citizenid == vehicleData.owner then
		Parking.Functions.CreateTargetEntityMenu(tempVeh)
		TriggerServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', vehicleData.plate)
	end
end

function Parking.Functions.SpawnVehicleChecker()
	while true do
		Wait(100)
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
							Draw3DText(v.location.x, v.location.y, v.location.z, "Model: ~b~"..model.."~s~" .. '\n' .. "Brand: ~o~"..brand.."~s~" .. '\n' .. "Plate: ~g~"..plate.."~s~" .. '\n' .. "Owner: ~y~"..owner.."~s~" , 0, 0.04, 0.04)
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

function Parking.Functions.DriveOrPark()
	while true do
		Wait(0)
		if isLoggedIn then
			if IsPedInAnyVehicle(GetPlayerPed(-1)) then
				local storedVehicle = Parking.Functions.GetPedInStoredCar(GetPlayerPed(-1))
				if IsControlJustReleased(0, 51) then -- E
					if storedVehicle ~= false then
						Parking.Functions.Drive(storedVehicle)
					else
						local veh = GetVehiclePedIsIn(GetPlayerPed(-1))
						if veh ~= 0 then
							local speed = GetEntitySpeed(veh)
							if speed > 0.1 then
								DisplayHelpText("stop the car")
							elseif IsThisModelACar(GetEntityModel(veh)) or IsThisModelABike(GetEntityModel(veh)) or IsThisModelABicycle(GetEntityModel(veh)) then
								Parking.Functions.Save(veh)
							else
								DisplayHelpText("only allow car")
							end
						end
					end
				end
			else
				Wait(500)
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
		if Trim(LocalVehicles[i].plate) == Trim(data.plate) then
			LocalVehicles[i].blip = Parking.Functions.CreateParkedBlip(data)
			break
		end
	end
end

function Parking.Functions.RefreshVehicles(vehicles)
	GlobalVehicles = vehicles
	Parking.Functions.RemoveVehicles(vehicles)
	Citizen.Wait(1000)
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
            if parkMenu ~= nil then
                exports['qb-radialmenu']:RemoveOption(parkMenu)
                parkMenu = nil
            end
            parkMenu = exports['qb-radialmenu']:AddOption({
                id = 'park_vehicles_menu',
                title = 'Parked Menu',
                icon = "square-parking",
                type = 'client',
                event = "mh-parkingV2:client:GetVehicleMenu",
                shouldClose = true
            }, parkMenu)
        end)
    elseif Config.Framework == 'esx' then
        lib.addRadialItem({
            {
                id = 'park_vehicles_menu',
                label = 'Parked Menu',
                icon = 'square-parking',
                onSelect = function()
                    TriggerEvent("mh-parkingV2:client:GetVehicleMenu")
                end
            }
        })
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
