local QBCore = exports['qb-core']:GetCoreObject()

-- Config
local lockpickTime = 5000 -- ms
local lockpickRange = 2.5
local successChance = 85 -- percent

-- Command: /autolockpick
RegisterCommand("autolockpick", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Try vehicle first
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, lockpickRange, 0, 71)
    if vehicle ~= 0 then
        autoLockpickVehicle(vehicle)
        return
    end

    -- Try door (if using doorlock system, integrate here)
    QBCore.Functions.Notify("No vehicle nearby. Door lockpicking not implemented yet.", "error")
end)

function autoLockpickVehicle(vehicle)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_WELDING", 0, true)
    QBCore.Functions.Notify("Lockpicking vehicle...", "primary")

    Wait(lockpickTime)
    ClearPedTasks(ped)

    if math.random(100) <= successChance then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        QBCore.Functions.Notify("Vehicle unlocked!", "success")
    else
        QBCore.Functions.Notify("Lockpick failed!", "error")
    end
end
