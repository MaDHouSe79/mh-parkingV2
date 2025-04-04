--[[ ===================================================== ]] --
--[[          MH Realistic Parking V2 by MaDHouSe79        ]] --
--[[ ===================================================== ]] --
CreateCallback("mh-parkingV2:server:SaveCar", function(source, cb, data) cb(Parking.Functions.Save(source, data)) end)
CreateCallback("mh-parkingV2:server:DriveCar", function(source, cb, data) cb(Parking.Functions.Drive(source, data)) end)
CreateCallback("mh-parkingV2:server:GetVehicles", function(source, cb) cb(Parking.Functions.GetVehicles(source)) end)
RegisterServerEvent('mh-parkingV2:server:CreateOwnerVehicleBlip', function(plate) Parking.Functions.CreateOwnerVehicleBlip(source, plate) end)
RegisterServerEvent('mh-parkingV2:server:RefreshVehicles', function() Parking.Functions.RefreshVehicles(source) end)
RegisterNetEvent('mh-parkingV2:server:OnJoin', function() Parking.Functions.OnJoin(source) end)
CreateThread(function() Parking.Functions.Init() end)