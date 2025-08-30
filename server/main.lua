--[[ ===================================================== ]] --
--[[               MH Parking V2 by MaDHouSe79             ]] --
--[[ ===================================================== ]] --
CreateCallback("mh-parkingV2:server:SaveCar", function(source, cb, data) cb(Parking.Functions.Save(source, data)) end)
CreateCallback("mh-parkingV2:server:DriveCar", function(source, cb, data) cb(Parking.Functions.Drive(source, data)) end)
CreateCallback("mh-parkingV2:server:GetVehicles", function(source, cb) cb(Parking.Functions.GetVehicles(source)) end)
CreateCallback("mh-parkingV2:server:GetTrailerLoad", function(source, cb, data) cb(Parking.Functions.GetTrailerLoad(source, data)) end)
RegisterServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', function(plate) Parking.Functions.CreateOwnerVehicleBlip(source, plate) end)
RegisterServerEvent('mh-parkingV2:server:RefreshVehicles', function() Parking.Functions.RefreshVehicles(source) end)
RegisterNetEvent("mh-parkingV2:server:EnteringVehicle", function(currentVehicle, currentSeat, vehicleName, netId) Parking.Functions.EnteringVehicle(source, currentVehicle, currentSeat, vehicleName, netId) end)
RegisterNetEvent('mh-parkingV2:server:LeftVehicle', function(currentVehicle, currentSeat, vehicleName, netId) Parking.Functions.LeftVehicle(source, currentVehicle, currentSeat, vehicleName, netId) end)
RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel) Parking.Functions.Impound(source, plate) end)
RegisterNetEvent('mh-parkingV2:server:OnJoin', function() Parking.Functions.OnJoin(source) end)
CreateThread(function() Parking.Functions.Init() end)