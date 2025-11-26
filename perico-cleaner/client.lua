local QBCore = exports['qb-core']:GetCoreObject()
local cleanerEnabled = false

local function isInWhitelistZone(pos)
    for _, zone in pairs(Config.WhitelistZones) do
        if #(pos - zone.coords) < zone.radius then
            return true
        end
    end
    return false
end

local function cleanGreenery()
    for _, model in pairs(Config.GreeneryModels) do
        local hash = GetHashKey(model)
        if not IsModelValid(hash) then goto continue end
        for obj in EnumerateObjects() do
            if GetEntityModel(obj) == hash then
                local pos = GetEntityCoords(obj)
                if not isInWhitelistZone(pos) then
                    DeleteEntity(obj)
                end
            end
        end
        ::continue::
    end
end

function EnumerateObjects()
    return coroutine.wrap(function()
        local handle, object = FindFirstObject()
        if not handle or handle == -1 then return end
        local finished = false
        repeat
            coroutine.yield(object)
            finished, object = FindNextObject(handle)
        until not finished
        EndFindObject(handle)
    end)
end

RegisterCommand("cleanfps", function()
    cleanerEnabled = not cleanerEnabled
    if cleanerEnabled then
        QBCore.Functions.Notify("FPS cleaner activated", "success")
        cleanGreenery()
    else
        QBCore.Functions.Notify("FPS cleaner deactivated", "error")
    end
end)

CreateThread(function()
    Wait(5000)
    if Config.AutoRunOnCayo then
        local coords = GetEntityCoords(PlayerPedId())
        if coords.x > 3000.0 and coords.y < -4000.0 then
            cleanerEnabled = true
            cleanGreenery()
        end
    end
end)
