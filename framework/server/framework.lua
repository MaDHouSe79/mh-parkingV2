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