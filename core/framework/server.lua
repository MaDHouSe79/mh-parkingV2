--[[ ===================================================== ]] --
--[[               MH Parking V2 by MaDHouSe79             ]] --
--[[ ===================================================== ]] --
Framework, CreateCallback, AddCommand = nil, nil, nil
if GetResourceState("es_extended") ~= 'missing' then
    Config.Framework = 'esx'
    Framework = exports['es_extended']:getSharedObject()
    CreateCallback = Framework.RegisterServerCallback
    AddCommand = Framework.RegisterCommand
    function GetPlayers() return Framework.Players end
    function GetPlayer(source) return Framework.GetPlayerFromId(source) end
    function GetJob(source) return Framework.GetPlayerFromId(source).job end
    function GetCitizenId(src) local xPlayer = GetPlayer(src) return xPlayer.identifier end
    function GetCitizenFullname(src) local xPlayer = GetPlayer(src) return xPlayer.name end
elseif GetResourceState("qb-core") ~= 'missing' then
    Config.Framework = 'qb'
    Framework = exports['qb-core']:GetCoreObject()
    CreateCallback = Framework.Functions.CreateCallback
    AddCommand = Framework.Commands.Add
    function GetPlayers() return Framework.Players end
    function GetPlayer(source) return Framework.Functions.GetPlayer(source) end
    function GetJob(source) return Framework.Functions.GetPlayer(source).PlayerData.job end
    function GetPlayerDataByCitizenId(citizenid) return Framework.Functions.GetPlayerByCitizenId(citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(citizenid) end
    function GetCitizenId(src) local xPlayer = GetPlayer(src) return xPlayer.PlayerData.citizenid end
    function GetCitizenFullname(src) local xPlayer = GetPlayer(src) return xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname end
elseif GetResourceState("qbx_core") ~= 'missing' then
    Config.Framework = 'qb'
    Framework = exports['qb-core']:GetCoreObject()
    CreateCallback = Framework.Functions.CreateCallback
    AddCommand = Framework.Commands.Add
    function GetPlayers() return Framework.Players end
    function GetPlayer(source) return Framework.Functions.GetPlayer(source) end
    function GetJob(source) return Framework.Functions.GetPlayer(source).PlayerData.job end
    function GetPlayerDataByCitizenId(citizenid) return Framework.Functions.GetPlayerByCitizenId(citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(citizenid) end
    function GetCitizenId(src) local xPlayer = GetPlayer(src) return xPlayer.PlayerData.citizenid end
    function GetCitizenFullname(src) local xPlayer = GetPlayer(src) return xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname end
end

function Notify(src, message, type, length)
    if GetResourceState("ox_lib") ~= 'missing' then
        lib.notify(src, {title = "MH Parking V2", description = message, type = type})
    else
        Framework.Functions.Notify(src, {text = "MH Parking V2", caption = message}, type, length)
    end
end