local QBCore = exports['qb-core']:GetCoreObject()

-- Register qb-target zones client-side
CreateThread(function()
    for _, loc in pairs(Config.StartLocations) do
        exports['qb-target']:AddBoxZone(loc.name, loc.coords, loc.size[1], loc.size[2], {
            name = loc.name,
            heading = 0,
            debugPoly = false, -- set true to visualize zone
            minZ = loc.minZ,
            maxZ = loc.maxZ
        }, {
            options = {
                {
                    type = "server",
                    event = "gcore:transporter:start",
                    icon = loc.icon,
                    label = loc.label,
                    job = {"all"}
                }
            },
            distance = 2.0
        })
    end
end)

-- Handle cargo assignment
RegisterNetEvent("gcore:transporter:assignJob")
AddEventHandler("gcore:transporter:assignJob", function(cargo, delivery)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local propHash = GetHashKey(cargo.prop)
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(0) end

    local cargoObj = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, true)

    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
    if veh ~= 0 then
        local boneIndex = GetEntityBoneIndexByName(veh, "boot")
        if boneIndex ~= -1 then
            AttachEntityToEntity(cargoObj, veh, boneIndex, 0.0, -0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            QBCore.Functions.Notify("Cargo loaded in trunk. Drive to delivery!", "primary")
        else
            AttachEntityToEntity(cargoObj, ped, GetPedBoneIndex(ped, 57005), 0.2, 0.0, -0.1, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
            QBCore.Functions.Notify("No trunk detected, carry cargo manually!", "error")
        end
    else
        AttachEntityToEntity(cargoObj, ped, GetPedBoneIndex(ped, 57005), 0.2, 0.0, -0.1, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
        QBCore.Functions.Notify("No vehicle nearby, carry cargo manually!", "error")
    end

    SetNewWaypoint(delivery.x, delivery.y)

    CreateThread(function()
        while true do
            local dist = #(GetEntityCoords(ped) - delivery)
            if dist < 5.0 then
                DeleteEntity(cargoObj)
                TriggerServerEvent("gcore:transporter:complete", cargo)
                break
            end
            Wait(1000)
        end
    end)
end)
