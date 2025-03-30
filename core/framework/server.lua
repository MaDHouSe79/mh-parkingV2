--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
Framework = nil
CreateCallback = nil

if GetResourceState("es_extended") ~= 'missing' then
    Config.Framework = 'esx'
    Framework = exports['es_extended']:getSharedObject()
    CreateCallback = Framework.RegisterServerCallback
    function GetPlayers() return Framework.Players end
    function GetPlayer(source) return Framework.GetPlayerFromId(source) end
    function GetJob(source) return Framework.GetPlayerFromId(source).job end
    function Notify(src, message, type, length) TriggerClientEvent("mh-hunters:client:notify", src, message, type, length) end
elseif GetResourceState("qb-core") ~= 'missing' then
    Config.Framework = 'qb'
    Framework = exports['qb-core']:GetCoreObject()
    CreateCallback = Framework.Functions.CreateCallback
    function GetPlayers() return Framework.Players end
    function GetPlayer(source) return Framework.Functions.GetPlayer(source) end
    function GetJob(source) return Framework.Functions.GetPlayer(source).PlayerData.job end
    function Notify(src, message, type, length) TriggerClientEvent("mh-parkingV2:client:notify", src, message, type, length) end
elseif GetResourceState("qbx-core") ~= 'missing' then
    Config.Framework = 'qbx'
    Framework = exports['qbx-core']:GetCoreObject()
    CreateCallback = Framework.Functions.CreateCallback
    function GetPlayers() return Framework.Players end
    function GetPlayer(source) return Framework.Functions.GetPlayer(source) end
    function GetJob(source) return Framework.Functions.GetPlayer(source).PlayerData.job end
    function Notify(src, message, type, length) TriggerClientEvent("mh-parkingV2:client:notify", src, message, type, length) end
end

function CreateVehicleList()
    local result = nil
    local vehicles = {}
    if Config.Framework == 'esx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE stored = ?", {3})
    elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
        result = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE state = ?", {3})
    end
    if type(result) == 'table' then
        for k, v in pairs(result) do
            local fullname = "unknow"
            if Config.Framework == 'esx' then
                local char = MySQL.Sync.fetchAll("SELECT * FROM users WHERE owner = ?", {v.citizenid})[1]
                if char then fullname = char.firstname.. ' ' ..char.lastname end
                local tmpVehicles = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE stored = ? AND owner = ?", {3, v.citizenid})[1]
                local mods = json.decode(tmpVehicles.vehicle)
                local coords = json.decode(tmpVehicles.location)
                vehicles[#vehicles + 1] = {citizenid = tmpVehicles.owner, fullname = fullname, plate = tmpVehicles.plate, model = mods.model, fuel = mods.fuelLevel, engine = mods.engineHealth, body = mods.bodyHealth, mods = mods, location = coords}
             elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
                local target = Framework.Functions.GetPlayerByCitizenId(v.citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(v.citizenid)
                fullname = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
                local tmpVehicles = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE state = ? and plate = ?", {3, v.plate})[1]
                local mods = json.decode(tmpVehicles.mods)
                local coords = json.decode(tmpVehicles.location)
                vehicles[#vehicles + 1] = {citizenid = tmpVehicles.citizenid, fullname = fullname, plate = tmpVehicles.plate, model = tmpVehicles.vehicle, fuel = tmpVehicles.fuel, engine = tmpVehicles.engine, body = tmpVehicles.body, mods = mods, location = coords}
                if target.PlayerData.citizenid == v.citizenid and target.PlayerData.source ~= nil then
                    TriggerClientEvent("qb-vehiclekeys:client:AddKeys", target.PlayerData.source, tmpVehicles.plate)
                end
            end
        end
    end
    return vehicles
end
