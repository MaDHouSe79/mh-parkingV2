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

# My Youtube Channel
- [Subscribe](https://www.youtube.com/c/@MaDHouSe79) 

# MH Parking V2 (QB/QBX/ESX) by MaDHouSe79
- I rewrote the mh-parking script and now your vehicles are automatically parked, this happens when you get out or get in the vehicle.
- I removed the F5 park/unpark and everything else that was no longer needed.
- The Impound should also work automatically and the vehicle should disappear when the police impound a vehicle.
- Auto park only when your engine is off, you can change this in the `sv_config.lua` file,
- when you press `F` sort it will park and when you hold the `F` it let the engine running and it will not park,
- and yes your vehicle will be back at the park location after server restart.
- Everybody can park but vip players can park more vehicles then the max default in `sv_config.lua`. (SV_Config.Maxparking)
- You can access the park menu with the radial menu.
  
# Dependencies (QB/ESX)
- [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3)
- [ox_lib](https://github.com/overextended/ox_lib/releases)
- [qb-core](https://github.com/qbcore-framework/qb-core) or [qbx-core](https://github.com/Qbox-project) or [esx](https://github.com/esx-framework)
- [qb-policejob](https://github.com/qbcore-framework/qb-policejob) (for qb-core)
- [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys) (for qb-core)

# Installation
- Step 1: First stop your server.
- Step 2: Copy the directory `mh-parkinV2` to `resources/[mh]/`.
- Stap 3: Add `ensure [mh]` in `server.cfg` below `ensure [defaultmaps]`.
- Step 4: Start your server.  

# Commands
- `/toggleparktext` Disable or Enable the text above the parked vehicles. (for streamers)
- `/parkmenu` Open the parked menu so you can set a waypoint.
- `/addvip [id] [amount]` Add a player as vip (admin only)
- `/removevip [id]` Remove a vip player (admin only)

# Save front wheels angle
- Before you press `F` press the keys `A` or `D` to turn your wheels and it will save that angle on your parked vehicle.

# Read Files
[README FILES](https://github.com/MaDHouSe79/mh-parkingV2/tree/main/readme)

# Screenshots
![alttext](https://github.com/MaDHouSe79/mh-parkingV2/blob/main/screenshots/parked.png)

# LICENSE
[GPL LICENSE](./LICENSE)<br />
&copy; [MaDHouSe79](https://www.youtube.com/@MaDHouSe79)
