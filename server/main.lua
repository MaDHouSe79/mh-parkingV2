--[[ ===================================================== ]] --
--[[          MH Realistic Parking V2 by MaDHouSe79        ]] --
--[[ ===================================================== ]] --
CreateCallback("mh-parkingV2:server:saveCar", function(source, cb, data) cb(Parking.Functions.Save(source, data)) end)
CreateCallback("mh-parkingV2:server:driveCar", function(source, cb, data) cb(Parking.Functions.Drive(source, data)) end)
CreateCallback("mh-parkingV2:server:GetVehicles", function(source, cb) cb(Parking.Functions.GetVehicles(source)) end)
RegisterServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', function(plate) Parking.Functions.CreateOwnerVehicleBlip(source, plate) end)
RegisterServerEvent('mh-parkingV2:server:refreshVehicles', function() Parking.Functions.RefreshVehicles(source) end)
RegisterServerEvent('mh-parkingV2:server:onjoin', function() TriggerClientEvent('mh-parkingV2:client:onjoin', source, SV_Config) end)
CreateThread(function()	Parking.Functions.Init() end)