<p align="center">
    <img width="140" src="https://icons.iconarchive.com/icons/iconarchive/red-orb-alphabet/128/Letter-M-icon.png" />  
    <h1 align="center">Hi 👋, I'm MaDHouSe</h1>
    <h3 align="center">A passionate allround developer </h3>    
</p>

<p align="center">
  <a href="https://github.com/MaDHouSe79/mh-parkingV2/issues">
    <img src="https://img.shields.io/github/issues/MaDHouSe79/mh-parkingV2"/> 
  </a>
  <a href="https://github.com/MaDHouSe79/mh-parkingV2/watchers">
    <img src="https://img.shields.io/github/watchers/MaDHouSe79/mh-parkingV2"/> 
  </a> 
  <a href="https://github.com/MaDHouSe79/mh-parkingV2/network/members">
    <img src="https://img.shields.io/github/forks/MaDHouSe79/mh-parkingV2"/> 
  </a>  
  <a href="https://github.com/MaDHouSe79/mh-parkingV2/stargazers">
    <img src="https://img.shields.io/github/stars/MaDHouSe79/mh-parkingV2?color=white"/> 
  </a>
  <a href="https://github.com/MaDHouSe79/mh-parkingV2/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/MaDHouSe79/mh-parkingV2?color=black"/> 
  </a>      
</p>

# My Youtube Channel and Discord
- [Subscribe](https://www.youtube.com/c/@MaDHouSe79) 
- [Discord](https://discord.gg/vJ9EukCmJQ)

# MH Parking V2 by MaDHouSe79
- I rewrote the parking script and now your vehicles are automatically parked, this happens when you get out or get in the vehicle.
- I remove the F5 park/unpark and everything else that was no longer needed.
- The Impound should also work automatically and the vehicle should disappear when the police impound a vehicle.

# Dependencies
- [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3)
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-policejob](https://github.com/qbcore-framework/qb-policejob)
- [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys)
- 
# Database
```sql
ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS location TEXT NULL DEFAULT NULL
ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS street TEXT NULL DEFAULT NULL
```

# Installation
- Step 1: First stop your server.
- Step 2: Copy the directory `mh-parkinV2` to `resources/[mh]/`.
- Stap 3: Add `ensure [mh]` in `server.cfg` below `ensure [defaultmaps]`.
- Step 4: Add the database table to your player_vehicles table in your database.
- Step 5: Start your server.  

# Installation QB-Garagae
[README FILES](https://github.com/MaDHouSe79/mh-parkingV2/tree/main/readme)

# Impound 
- The Impound should also work automatically and the vehicle should disappear when the police impound the vehicle.

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

# 🐞 Any bugs issues or suggestions, let my know. 👊😎

# LICENSE
[GPL LICENSE](./LICENSE)<br />
&copy; [MaDHouSe79](https://www.youtube.com/@MaDHouSe79)
