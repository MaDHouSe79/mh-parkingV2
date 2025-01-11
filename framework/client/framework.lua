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

function Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

function Round(value, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / (power)
end

function SamePlates(plate1, plate2)
    return (Trim(plate1) == Trim(plate2))
end

function GetDistance(pos1, pos2)
    return #(vector3(pos1.x, pos1.y, pos1.z) - vector3(pos2.x, pos2.y, pos2.z))
end

function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(50)
    end
end

function GetPedVehicleSeat(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for i = -2, GetVehicleMaxNumberOfPassengers(vehicle) do
        if(GetPedInVehicleSeat(vehicle, i) == ped) then return i end
    end
    return -2
end

function GetClosestVehicle(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

function Notify(message, type, length)
    if Config.NotifyScript == "qb" then
        Framework.Functions.Notify(message, type, length)
    elseif Config.NotifyScript == "ox_lib" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        lib.notify({title = "MH Parking V2", description = message, type = type})
    elseif Config.NotifyScript == "k5_notify" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        exports["k5_notify"]:notify("MH Parking V2", message, "k5style", length)
    elseif Config.NotifyScript == "okokNotify" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        exports['okokNotify']:Alert("MH Parking V2", message, length, type)
    elseif Config.NotifyScript == "Roda_Notifications" and GetResourceState(Config.NotifyScript) ~= 'missing' then
        exports['Roda_Notifications']:showNotify("MH Parking V2", message, type, length)
    end
end

function Draw3DText(x, y, z, textInput, fontId, scaleX, scaleY)
    local p = GetGameplayCamCoords()
    local dist = #(p - vector3(x, y, z))
    local scale = (1 / dist) * 20
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    SetTextScale(scaleX * scale, scaleY * scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(250, 250, 250, 255)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x, y, z + 2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
