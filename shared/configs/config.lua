--[[ ===================================================== ]] --
--[[               MH Parking V2 by MaDHouSe79             ]] --
--[[ ===================================================== ]] --
Config = {}                                   -- Placeholder don't edit or change or remove this.
Config.Debug = false                          -- Default false, if true this will show prints in the server console.
Config.DebugBlipForRadius = true              -- If true you see a circle aera on the map, use this for debug only.
----------------------------------------------------------------------------
Config.UseParkWithCommand = false             -- When true auto park is diabled.
Config.ParkingButton = 166                    -- F5 (vehicle exit and or park)
Config.KeyParkBindButton = "F5"               -- F5 keybinder 
Config.OnlyAutoParkWhenEngineIsOff = true     -- When true and Config.UseParkWithCommand = true this wil be automatic false.
Config.FuelScript = 'mh-fuel'                 -- Default is LegacyFuel or qb-fuel, if you use a other fuel script, for example ox_fuel or mh-fuel
Config.ForceVehicleOnGound = true             -- If true this will force parked vehicles on the ground, sometimes the vehicles are in the air and by enable this is force the vehicle to the ground
Config.ViewDistance = true                    -- If true parked vehicles are only visable in 100 meters around the players. (true For performance)
Config.ParkedViewDistance = 150               -- Default 100 if your distance is over 100 meters the vehicles in that area will not render on screen. (150 For performance)
Config.UseParkedBlips = true                  -- if true players can see a blip of the parked vehicle on the map (false For performance)
Config.UseAsVip = true                        -- if true `Config.Maxparking` does not work on vip players and you need to add a amount per player.
Config.Maxparking = 1                         -- Default 1, this is max parked allowed per player, don't go to high with this...
Config.UseVehicleOwnerText = true             -- If true show the owner and vehicle text above vehicles when parked. (false For performance)
Config.VehicleOwnerTextDisplayDistance = 15   -- distance before you see any text by parked vehicles.
Config.ParkVehiclesWithTrailers = false       -- Keep it false, don't use this for now..... (false For performance)
Config.VehicleDoorsUnlockedForOwners = true   -- if true parked vehicles are unlocked for vehicle owners, you must own this vehicle before this works.
Config.DisableParkedVehiclesCollision = false -- Default false, when true to disable the parked vehicle collision, players can't ram the parked vehicles.
----------------------------------------------------------------------------
-- This is when you close to a gasstation, you can't use the park system.
-- This goes automatic so leave it as it is.
Config.DisableNeedByPumpModels = {
    ['prop_vintage_pump'] = true,
    ['prop_gas_pump_1a'] = true,
    ['prop_gas_pump_1b'] = true,
    ['prop_gas_pump_1c'] = true,
    ['prop_gas_pump_1d'] = true,
    ['prop_gas_pump_old2'] = true,
    ['prop_gas_pump_old3'] = true
}