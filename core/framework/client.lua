--[[ ===================================================== ]] --
--[[       MH Realistic Parking V2 Script by MaDHouSe      ]] --
--[[ ===================================================== ]] --
Framework = nil
PlayerData = {}
isLoggedIn = false
TriggerCallback = nil
OnPlayerLoaded = nil
OnPlayerUnload = nil
OnJobUpdate = nil
SetVehicleProperties = nil
GetVehicleProperties = nil

if GetResourceState("es_extended") ~= 'missing' then
    Config.Framework = 'esx'
    Framework = exports['es_extended']:getSharedObject()
    TriggerCallback = Framework.TriggerServerCallback
    OnPlayerLoaded = 'esx:playerLoaded'
    OnPlayerUnload = 'esx:playerUnLoaded'
    OnJobUpdate = 'esx:setJob'
    SetVehicleProperties = Framework.Game.SetVehicleProperties
    GetVehicleProperties = Framework.Game.GetVehicleProperties
    function GetPlayerData() TriggerCallback('esx:getPlayerData', function(data) PlayerData = data end) return PlayerData end
    function IsDead() return (GetEntityHealth(PlayerPedId()) <= 0) end
    function SetJob(job) PlayerData.job = job end
elseif GetResourceState("qb-core") ~= 'missing' then
    Config.Framework = 'qb'
    Framework = exports['qb-core']:GetCoreObject()
    TriggerCallback = Framework.Functions.TriggerCallback
    OnPlayerLoaded = 'QBCore:Client:OnPlayerLoaded'
    OnPlayerUnload = 'QBCore:Client:OnPlayerUnload'
    OnJobUpdate = 'QBCore:Client:OnJobUpdate'
    SetVehicleProperties = Framework.Functions.SetVehicleProperties
    GetVehicleProperties = Framework.Functions.GetVehicleProperties
    function GetPlayerData() return Framework.Functions.GetPlayerData() end
    function IsDead() return Framework.Functions.GetPlayerData().metadata['isdead'] end
    function SetJob(job) PlayerData.job = job end
elseif GetResourceState("qbx-core") ~= 'missing' then
    Config.Framework = 'qbx'
    Framework = exports['qbx-core']:GetCoreObject()
    TriggerCallback = Framework.Functions.TriggerCallback
    OnPlayerLoaded = 'QBCore:Client:OnPlayerLoaded'
    OnPlayerUnload = 'QBCore:Client:OnPlayerUnload'
    OnJobUpdate = 'QBCore:Client:OnJobUpdate'
    SetVehicleProperties = Framework.Functions.SetVehicleProperties
    GetVehicleProperties = Framework.Functions.GetVehicleProperties
    function GetPlayerData() return Framework.Functions.GetPlayerData() end
    function IsDead() return Framework.Functions.GetPlayerData().metadata['isdead'] end
    function SetJob(job) PlayerData.job = job end
end