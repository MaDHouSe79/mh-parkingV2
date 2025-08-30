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
    function Notify(src, message, type, length) TriggerClientEvent("mh-parkingV2:client:Notify", src, message, type, length) end
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
    function Notify(src, message, type, length) TriggerClientEvent("mh-parkingV2:client:Notify", src, message, type, length) end
end