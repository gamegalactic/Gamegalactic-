local QBCore = exports['qb-core']:GetCoreObject()

local hangarCoords = vector3(4511.39,-4468.95,4.19) -- Perico airstrip hangar
local spawnHeading = 90.0

-- Store plane
RegisterCommand('storeplane', function()
    local ped = PlayerPedId()
    if not IsPedInAnyPlane(ped) and not IsPedInAnyHeli(ped) then
        TriggerEvent('QBCore:Notify', 'You are not in an aircraft!', 'error')
        return
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        TriggerEvent('QBCore:Notify', 'No aircraft detected!', 'error')
        return
    end

    local coords = GetEntityCoords(veh)
    if #(coords - hangarCoords) > 50.0 then
        TriggerEvent('QBCore:Notify', 'You must be near the Perico hangar!', 'error')
        return
    end

    local props = QBCore.Functions.GetVehicleProperties(veh)
    if not props or not props.plate then
        TriggerEvent('QBCore:Notify', 'Failed to read aircraft properties.', 'error')
        return
    end

    TriggerServerEvent('perico_airgarage:storePlane', props)
    DeleteEntity(veh)
end, false)

-- Retrieve plane
RegisterCommand('getplane', function(_, args)
    local plate = args[1]
    if not plate then
        TriggerEvent('QBCore:Notify', 'Usage: /getplane [plate]', 'error')
        return
    end
    TriggerServerEvent('perico_airgarage:retrievePlane', plate)
end, false)

-- Spawn plane
RegisterNetEvent('perico_airgarage:spawnPlane', function(props)
    local model = props.model or props.modelHash
    if type(model) == 'string' then model = joaat(model) end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local veh = CreateVehicle(model, hangarCoords.x, hangarCoords.y, hangarCoords.z, spawnHeading, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)

    if props.plate then SetVehicleNumberPlateText(veh, props.plate) end
    QBCore.Functions.SetVehicleProperties(veh, props)

    SetVehicleEngineOn(veh, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    TriggerEvent('QBCore:Notify', 'Aircraft retrieved from Perico hangar.', 'success')
end)
