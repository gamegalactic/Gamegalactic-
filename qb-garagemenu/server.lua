-- qb-garagemenu/server.lua
QBCore = exports['qb-core']:GetCoreObject()

local function DebugPrint(msg)
    if Config.Debug then
        print("^3[qb-garagemenu]^7 " .. msg)
    end
end

-- Command to open garage menu
RegisterCommand("garage", function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:query(
        "SELECT * FROM player_vehicles WHERE citizenid = ?",
        {citizenid},
        function(result)
            DebugPrint("DB returned rows: " .. tostring(#result))

            -- Filter by allowed garages
            local filtered = {}
            for _, v in pairs(result) do
                if v.garage then
                    for _, g in pairs(Config.AllowedGarages) do
                        if v.garage == g then
                            table.insert(filtered, v)
                            break
                        end
                    end
                end
            end

            if #filtered > 0 then
                TriggerClientEvent("qb-garagemenu:openMenu", src, filtered)
            else
                TriggerClientEvent("QBCore:Notify", src, "No vehicles in allowed garages!", "error")
            end
        end
    )
end)

-- Spawn chosen vehicle
RegisterNetEvent("qb-garagemenu:spawnVehicle", function(vehicleData)
    local src = source
    DebugPrint("Sending vehicleData to client: " .. json.encode(vehicleData or {}))
    TriggerClientEvent("qb-garagemenu:spawnOwnedVehicle", src, vehicleData)

    if vehicleData and vehicleData.plate then
        exports.oxmysql:update(
            "UPDATE player_vehicles SET state = 0 WHERE plate = ?",
            {vehicleData.plate}
        )
    end
end)
