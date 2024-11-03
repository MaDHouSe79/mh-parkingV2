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

# Videos
[Watch](https://youtu.be/cLCthqPRLQQ)
[Watch](https://youtu.be/QRJZ2r7FD4w)

# Dependencies
- [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3)
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-policejob](https://github.com/qbcore-framework/qb-policejob)
- [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys)

## Installation
- Step 1: First stop your server.
- Step 2: Copy the directory `mh-parkinV2` to `resources/[mh]/`.
- Step 3: Add the database table to your player_vehicles table in your database.
- Step 4: Start your server.  

# Database
```sql
ALTER TABLE `player_vehicles` ADD COLUMN `location` TEXT NULL DEFAULT NULL
```



# LICENSE
[GPL LICENSE](./LICENSE)<br />
&copy; [MaDHouSe79](https://www.youtube.com/@MaDHouSe79)
