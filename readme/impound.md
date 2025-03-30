# Impound 
- The Impound should also work automatically and the vehicle should disappear when the police impound the vehicle.
- Impound Example
```lua
local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
if vehicle ~= 0 and distance <= 3.0 then
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name == 'police' and PlayerData.job.onduty then
        local plate = QBCore.Functions.GetPlate(vehicle)
        TriggerServerEvent('mh-parkingV2:server:Impound', plate)
    end
end
```

# Towing vehicle example
- this for mechanics (client side call)
```lua
local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
if vehicle ~= 0 and distance <= 3.0 then
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name == 'mechanic' and PlayerData.job.onduty then
        local plate = QBCore.Functions.GetPlate(vehicle)
        TriggerServerEvent('mh-parkingV2:server:TowVehicle', plate)
    end
end
```