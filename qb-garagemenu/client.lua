-- qb-garagemenu/client.lua

local function DebugPrint(msg)
    if Config.Debug then
        print("^3[qb-garagemenu]^7 " .. msg)
    end
end

-- Open garage menu
RegisterNetEvent("qb-garagemenu:openMenu", function(vehicles)
    DebugPrint("Opening garage menu with " .. tostring(#vehicles) .. " vehicles")

    local menu = {
        {
            header = "?? Garage Vehicles",
            isMenuHeader = true
        }
    }

    for _, v in pairs(vehicles) do
        local header = (v.vehicle or "Unknown") .. " [" .. (v.plate or "NoPlate") .. "]"
        local txt = v.state == 1 and "Stored" or "Out"

        DebugPrint("Vehicle found: " .. header .. " state=" .. tostring(v.state))

        menu[#menu+1] = {
            header = header,
            txt = txt,
            params = {
                event = "qb-garagemenu:chooseVehicle",
                args = v
            }
        }
    end

    if #menu > 1 then
        exports['qb-menu']:openMenu(menu)
    else
        TriggerEvent("QBCore:Notify", "No vehicles available!", "error")
    end
end)

-- Handle vehicle choice
RegisterNetEvent("qb-garagemenu:chooseVehicle", function(vehicleData)
    if not vehicleData then
        DebugPrint("ERROR: chooseVehicle called with nil data")
        return
    end
    DebugPrint("Vehicle chosen: " .. (vehicleData.vehicle or "Unknown") .. " [" .. (vehicleData.plate or "NoPlate") .. "]")
    TriggerServerEvent("qb-garagemenu:spawnVehicle", vehicleData)
end)

-- Spawn owned vehicle with saved properties
RegisterNetEvent("qb-garagemenu:spawnOwnedVehicle", function(vehicleData)
    if not vehicleData or not vehicleData.vehicle then
        DebugPrint("ERROR: spawnOwnedVehicle received nil or invalid data")
        TriggerEvent("QBCore:Notify", "Vehicle spawn failed: no data received.", "error")
        return
    end

    DebugPrint("Spawning vehicle: " .. vehicleData.vehicle .. " [" .. (vehicleData.plate or "NoPlate") .. "]")

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local model = joaat(vehicleData.vehicle)
    if not IsModelInCdimage(model) then
        DebugPrint("ERROR: Model " .. vehicleData.vehicle .. " not found in game files!")
        TriggerEvent("QBCore:Notify", "Invalid vehicle model: " .. vehicleData.vehicle, "error")
        return
    end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local veh = CreateVehicle(model, coords.x + Config.DeliveryOffset, coords.y + Config.DeliveryOffset, coords.z, GetEntityHeading(ped), true, false)
    SetVehicleNumberPlateText(veh, vehicleData.plate or "TEST")

    if QBCore and QBCore.Functions and QBCore.Functions.SetVehicleProperties then
        QBCore.Functions.SetVehicleProperties(veh, vehicleData)
    end

    SetPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(model)

    TriggerEvent('QBCore:Notify', "Your vehicle has been delivered!", "success")
end)
local PAGE_SIZE = 10

RegisterNetEvent("qb-garagemenu:openMenu", function(vehicles, page)
    page = page or 1
    local total = #vehicles
    local startIndex = ((page - 1) * PAGE_SIZE) + 1
    local endIndex = math.min(startIndex + PAGE_SIZE - 1, total)

    DebugPrint("Opening garage menu page " .. page .. " showing vehicles " .. startIndex .. "-" .. endIndex .. " of " .. total)

    local menu = {
        {
            header = "?? Garage Vehicles (Page " .. page .. ")",
            isMenuHeader = true
        }
    }

    for i = startIndex, endIndex do
        local v = vehicles[i]
        if v then
            local header = (v.vehicle or "Unknown") .. " [" .. (v.plate or "NoPlate") .. "]"
            local txt = v.state == 1 and "Stored" or "Out"

            menu[#menu+1] = {
                header = header,
                txt = txt,
                params = {
                    event = "qb-garagemenu:chooseVehicle",
                    args = v
                }
            }
        end
    end

    -- Pagination controls
    if endIndex < total then
        menu[#menu+1] = {
            header = "?? Next Page",
            params = {
                event = "qb-garagemenu:openMenu",
                args = { vehicles = vehicles, page = page + 1 }
            }
        }
    end
    if page > 1 then
        menu[#menu+1] = {
            header = "?? Previous Page",
            params = {
                event = "qb-garagemenu:openMenu",
                args = { vehicles = vehicles, page = page - 1 }
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

-- Handle vehicle choice
RegisterNetEvent("qb-garagemenu:chooseVehicle", function(vehicleData)
    if not vehicleData then
        DebugPrint("ERROR: chooseVehicle called with nil data")
        return
    end
    DebugPrint("Vehicle chosen: " .. (vehicleData.vehicle or "Unknown") .. " [" .. (vehicleData.plate or "NoPlate") .. "]")
    TriggerServerEvent("qb-garagemenu:spawnVehicle", vehicleData)
end)
-- client.lua
RegisterCommand("spawncar", function()
    local model = "sultan"
    TriggerServerEvent("myresource:spawnVehicle", model)
end)

-- server.lua
RegisterNetEvent("myresource:spawnVehicle")
AddEventHandler("myresource:spawnVehicle", function(model)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, true)
    SetVehicleNumberPlateText(veh, "TEST"..math.random(100,999))
    SetEntityAsMissionEntity(veh, true, true)

    -- Give client control
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdCanMigrate(netId, true)
    TriggerClientEvent("myresource:vehicleSpawned", src, netId)
end)

-- client.lua (ownership)
RegisterNetEvent("myresource:vehicleSpawned")
AddEventHandler("myresource:vehicleSpawned", function(netId)
    local veh = NetToVeh(netId)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
end)
