--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
Config = {} -- Placeholder don't edit or change or remove this.

-- Target Script
Config.TargetScript = "qb-target" -- Default qb-target but you can also use ox_target.

-- Fuel Script
Config.FuelScript = 'LegacyFuel'  -- Default is LegacyFuel, if you use a other fuel script, for example cc-fuel

-- Notify Script
Config.DisableParkNotify = false  -- Default true, if false you get many notifications when you enter or leave the vehicle, all other notify massages are stil enable.
Config.NotifyScript = "qb"        -- Default qb, but you can use this scripts aswell (k5_notify, okokNotify, Roda_Notifications)

Config.ForceVehicleOnGound = true -- If true this will force parked vehicles on the ground, sometimes the vehicles are in the air and by enable this is force the vehicle to the ground

-- For performance
Config.ViewDistance = true        -- If true vehicles are only visable in 100 meters around the players.
Config.ParkedViewDistance = 100   -- Default 100 if your distance is over 100 meters the vehicles in that area will not render on screen.
Config.UseParkedBlips = true      -- if true players can see a blip of the parked vehicle on the map

----------------------------------------------------------------------------
-- This is when you need to fuel and you can't use the auto park system.
-- This goes automatic so leave it as it is.
Config.DisableNeedByPumpModels = {
    [-2007231801] = true,
    [1339433404] = true,
    [1694452750] = true,
    [1933174915] = true,
    [-462817101] = true,
    [-469694731] = true,
    [-164877493] = true
}
