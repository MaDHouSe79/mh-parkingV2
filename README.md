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

# MH Parking V2 by MaDHouSe79
- I rewrote the mh-parking script and now your vehicles are automatically parked, this happens when you get out or get in the vehicle.
- I removed the F5 park/unpark and everything else that was no longer needed.
- The Impound should also work automatically and the vehicle should disappear when the police impound a vehicle.
- Auto park only when your engine is off, you can change this in the config file,
- When you press `F` sort it will park and when you hold the `F` it let the engine running and it will not park,
- and yes your vehicle will be back at the park location after server restart.
  
# Dependencies (QB/ESX)
- [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3)
- [qb-core](https://github.com/qbcore-framework/qb-core) or [esx](https://github.com/esx-framework)
- [qb-policejob](https://github.com/qbcore-framework/qb-policejob) (for qb-core)
- [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys) (for qb-core)

# Installation
- Step 1: First stop your server.
- Step 2: Copy the directory `mh-parkinV2` to `resources/[mh]/`.
- Stap 3: Add `ensure [mh]` in `server.cfg` below `ensure [defaultmaps]`.
- Step 4: Start your server.  

# Commands
- `/toggleparktext` this disable or enable the text above the parked vehicles. (for streamers)
- `/parkmenu` to open the parked menu so you can set a waypoint.

# Installation QB-Garages
[README FILES](https://github.com/MaDHouSe79/mh-parkingV2/tree/main/readme)

# 🐞 Any bugs issues or suggestions, let my know. 👊😎

# LICENSE
[GPL LICENSE](./LICENSE)<br />
&copy; [MaDHouSe79](https://www.youtube.com/@MaDHouSe79)
