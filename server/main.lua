--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
CreateCallback('mh-parkingV2:server:isVehicleParked', function(source, cb, plate, state) cb(Parking.Functions.IsVehicleParked(plate, state)) end)
CreateCallback('mh-parkingV2:server:getVehicleData', function(source, cb, plate) cb(Parking.Functions.GetVehicleData(source, plate)) end)
CreateCallback("mh-parkingV2:server:GetVehicles", function(source, cb) cb(Parking.Functions.GetVehicles(source)) end)
CreateCallback("mh-parkingV2:server:save", function(source, cb, data) cb(Parking.Functions.Save(source, data)) end)
CreateCallback("mh-parkingV2:server:drive", function(source, cb, data) cb(Parking.Functions.Drive(source, data)) end)
AddEventHandler('onResourceStop', function(resource) if resource == GetCurrentResourceName() then playerId = -1 end end)
RegisterNetEvent('mh-parkingV2:server:setVehLockState', function(vehNetId, state) Parking.Functions.SetVehicleLockState(NetworkGetEntityFromNetworkId(vehNetId), state) end)
RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel) Parking.Functions.Impound(source, plate) end)
RegisterNetEvent('mh-parkingV2:server:Impound', function(plate) Parking.Functions.Impound(source, plate) end)
RegisterNetEvent('mh-parkingV2:server:TowVehicle', function(plate) Parking.Functions.TowVehicle(source, plate) end)
RegisterNetEvent("mh-parkingV2:server:enteringVehicle", function(currentVehicle, currentSeat, vehicleName, netId) Parking.Functions.EnteringVehicle(source, currentSeat, netId) end)
RegisterNetEvent('mh-parkingV2:server:leftVehicle', function(currentVehicle, currentSeat, vehicleName, netId) Parking.Functions.LeftVehicle(source, currentSeat, netId) end)
RegisterNetEvent('mh-parkingV2:server:refreshVehicles', function() Parking.Functions.RefreshVehicles(source, false) end)
RegisterNetEvent('mh-parkingV2:server:refreshVehiclesOnStart', function() Parking.Functions.RefreshVehicles(source, true) end)
RegisterNetEvent('mh-parkingV2:server:ClearAllSeats', function() Parking.Functions.ClearAllSeats(netid) end)
CreateThread(function() Parking.Functions.Init() end)
