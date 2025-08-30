--[[ ===================================================== ]] --
--[[               MH Parking V2 by MaDHouSe79             ]] --
--[[ ===================================================== ]] --
Framework, TriggerCallback, OnPlayerLoaded, OnPlayerUnload = nil, nil, nil, nil
OnJobUpdate, isLoggedIn, PlayerData = nil, false, {}
if GetResourceState("es_extended") ~= 'missing' then
    Config.Framework = 'esx'
    Framework = exports['es_extended']:getSharedObject()
    TriggerCallback = Framework.TriggerServerCallback
    OnPlayerLoaded = 'esx:playerLoaded'
    OnPlayerUnload = 'esx:playerUnLoaded'
    OnJobUpdate = 'esx:setJob'
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
    function GetPlayerData() return Framework.Functions.GetPlayerData() end
    function IsDead() return Framework.Functions.GetPlayerData().metadata['isdead'] end
    function SetJob(job) PlayerData.job = job end
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(data) PlayerData = data end)
end

function GetPedVehicleSeat(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for i = -2, GetVehicleMaxNumberOfPassengers(vehicle) do
        if(GetPedInVehicleSeat(vehicle, i) == ped) then return i end
    end
    return -2
end

function Notify(message, type, length)
    if GetResourceState("ox_lib") ~= 'missing' then
        lib.notify({title = "MH Parking V2", description = message, type = type})
    else
        QBCore.Functions.Notify({text = "MH Parking V2", caption = message}, type, length)
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

function DisplayHelpText(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(1)
    end
end

function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(1) end
    end
end

function GetStreetName(entity)
    return GetStreetNameFromHashKey(GetStreetNameAtCoord(GetEntityCoords(entity).x, GetEntityCoords(entity).y, GetEntityCoords(entity).z))
end

function GetVehicleAndTrailerBones(vehicle, trailer)
    local vehiclebone = -1
    if GetEntityBoneIndexByName(vehicle, 'attach_male') ~= -1 then
        vehiclebone = GetEntityBoneIndexByName(vehicle, 'attach_male')
    elseif GetEntityBoneIndexByName(vehicle, 'attach_female') ~= -1 then
        vehiclebone = GetEntityBoneIndexByName(vehicle, 'attach_female')
    end
    local trailerbone = -1
    if GetEntityBoneIndexByName(trailer, 'attach_male') ~= -1 then
        trailerbone = GetEntityBoneIndexByName(trailer, 'attach_male')
    elseif GetEntityBoneIndexByName(trailer, 'attach_female') ~= -1 then
        trailerbone = GetEntityBoneIndexByName(trailer, 'attach_female')
    end
    return vehiclebone, trailerbone
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

function DoVehicleDamage(vehicle, body, engine)
    local engine = engine + 0.0
    local body = body + 0.0
    if body < 900.0 then
        SmashVehicleWindow(vehicle, 0)
        SmashVehicleWindow(vehicle, 1)
        SmashVehicleWindow(vehicle, 2)
        SmashVehicleWindow(vehicle, 3)
        SmashVehicleWindow(vehicle, 4)
        SmashVehicleWindow(vehicle, 5)
        SmashVehicleWindow(vehicle, 6)
        SmashVehicleWindow(vehicle, 7)
    end
    if body < 800.0 then
        SetVehicleDoorBroken(vehicle, 0, true)
        SetVehicleDoorBroken(vehicle, 1, true)
        SetVehicleDoorBroken(vehicle, 2, true)
        SetVehicleDoorBroken(vehicle, 3, true)
        SetVehicleDoorBroken(vehicle, 4, true)
        SetVehicleDoorBroken(vehicle, 5, true)
        SetVehicleDoorBroken(vehicle, 6, true)
    end
    if engine < 700.0 then
        SetVehicleTyreBurst(vehicle, 1, false, 990.0)
        SetVehicleTyreBurst(vehicle, 2, false, 990.0)
        SetVehicleTyreBurst(vehicle, 3, false, 990.0)
        SetVehicleTyreBurst(vehicle, 4, false, 990.0)
    end
    if engine < 500.0 then
        SetVehicleTyreBurst(vehicle, 0, false, 990.0)
        SetVehicleTyreBurst(vehicle, 5, false, 990.0)
        SetVehicleTyreBurst(vehicle, 6, false, 990.0)
        SetVehicleTyreBurst(vehicle, 7, false, 990.0)
    end
    SetVehicleEngineHealth(vehicle, engine)
    SetVehicleBodyHealth(vehicle, body)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
end

function SetPedOutfit(ped)
    local data = Config.Outfit
    local hearTexture = math.random(1, 5)
    local hearItem = math.random(1, 2)
    if data["hair"] ~= nil then SetPedComponentVariation(ped, 2, hearItem, hearTexture, 0) end
    if data["beard"] ~= nil then SetPedComponentVariation(ped, 1, data["beard"].item, data["hair"].texture, 0) end
    if data["pants"] ~= nil then SetPedComponentVariation(ped, 4, data["pants"].item, data["pants"].texture, 0) end
    if data["arms"] ~= nil then SetPedComponentVariation(ped, 3, data["arms"].item, data["arms"].texture, 0) end
    if data["t-shirt"] ~= nil then SetPedComponentVariation(ped, 8, data["t-shirt"].item, data["t-shirt"].texture, 0) end
    if data["vest"] ~= nil then SetPedComponentVariation(ped, 9, data["vest"].item, data["vest"].texture, 0) end
    if data["torso2"] ~= nil then SetPedComponentVariation(ped, 11, data["torso2"].item, data["torso2"].texture, 0) end
    if data["shoes"] ~= nil then SetPedComponentVariation(ped, 6, data["shoes"].item, data["shoes"].texture, 0) end
    if data["bag"] ~= nil then SetPedComponentVariation(ped, 5, data["bag"].item, data["bag"].texture, 0) end
    if data["decals"] ~= nil then SetPedComponentVariation(ped, 10, data["decals"].item, data["decals"].texture, 0) end
    if data["mask"] ~= nil then SetPedComponentVariation(ped, 1, data["mask"].item, data["mask"].texture, 0) end
    if data["bag"] ~= nil then SetPedComponentVariation(ped, 5, data["bag"].item, data["bag"].texture, 0) end
    if data["hat"] ~= nil and data["hat"].item ~= -1 and data["hat"].item ~= 0 then SetPedPropIndex(ped, 0, data["hat"].item, data["hat"].texture, true) end
    if data["glass"] ~= nil and data["glass"].item ~= -1 and data["glass"].item ~= 0 then SetPedPropIndex(ped, 1, data["glass"].item, data["glass"].texture, true) end
    if data["ear"] ~= nil and data["ear"].item ~= -1 and data["ear"].item ~= 0 then SetPedPropIndex(ped, 2, data["ear"].item, data["ear"].texture, true) end
end

function GiveTakeAnimation(driver, player)
    LoadAnimDict('anim@mp_player_intmenu@key_fob@')
    TaskPlayAnim(driver, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    TaskPlayAnim(player, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    Wait(1000)
    if IsEntityPlayingAnim(driver, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3) then
        StopAnimTask(driver, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 8.0)
    end
    if IsEntityPlayingAnim(player, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3) then
        StopAnimTask(player, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 8.0)
    end
end