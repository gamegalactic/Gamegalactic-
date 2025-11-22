local QBCore = exports['qb-core']:GetCoreObject()

local function DebugPrint(msg)
    if Config.Debug then
        print("^3[TransporterJob]^7 " .. msg)
    end
end

-- Job start
RegisterNetEvent("gcore:transporter:start", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Optional job restriction
    if Config.RequiredJob and type(Config.RequiredJob) == "table" then
        local pj = Player.PlayerData.job and Player.PlayerData.job.name or nil
        local allowed = false
        for _, j in ipairs(Config.RequiredJob) do
            if pj == j then allowed = true break end
        end
        if not allowed then
            TriggerClientEvent("QBCore:Notify", src, "You don't have the required job to start this.", "error")
            DebugPrint(("Player %s blocked by job restriction. Current: %s"):format(src, tostring(pj)))
            return
        end
    end

    -- Require fake papers
    local item = Player.Functions.GetItemByName(Config.RequiredItem)
    if not item then
        TriggerClientEvent("QBCore:Notify", src, "You need Fake Papers (" .. Config.RequiredItemImage .. ") to start this job!", "error")
        DebugPrint("Player " .. src .. " missing required item: " .. Config.RequiredItem)
        return
    end

    -- Assign cargo + delivery
    local cargo = Config.CargoTypes[math.random(#Config.CargoTypes)]
    local delivery = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]

    if Config.SQLPersistence then
        MySQL.insert('INSERT INTO transporter_jobs (player_id, vehicle_plate, cargo_type, status) VALUES (?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            "UNKNOWN", -- optionally detect plate clientside and send to server
            cargo.prop,
            'active'
        })
    end

    TriggerClientEvent("QBCore:Notify", src, "Pickup cargo: " .. cargo.label, "success")
    TriggerClientEvent("gcore:transporter:assignJob", src, cargo, delivery)
end)

-- Job complete
RegisterNetEvent("gcore:transporter:complete", function(cargo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local payout = cargo.payout or 200
    Player.Functions.AddMoney("cash", payout, "Transporter Delivery")

    if Config.SQLPersistence then
        MySQL.update('UPDATE transporter_jobs SET status = ? WHERE player_id = ? AND cargo_type = ? AND status = ?', {
            'delivered',
            Player.PlayerData.citizenid,
            cargo.prop,
            'active'
        })
        MySQL.insert('INSERT INTO transporter_history (player_id, cargo_type, payout) VALUES (?, ?, ?)', {
            Player.PlayerData.citizenid,
            cargo.prop,
            payout
        })
    end

    TriggerClientEvent("QBCore:Notify", src, "Delivery complete! Earned $" .. payout, "success")
    DebugPrint("Player " .. src .. " delivered cargo: " .. cargo.label)
end)
-- Command to start transporter job manually
QBCore.Commands.Add("starttransporter", "Start the transporter job (requires fake papers)", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    -- Optional job restriction
    if Config.RequiredJob and type(Config.RequiredJob) == "table" then
        local pj = Player.PlayerData.job and Player.PlayerData.job.name or nil
        local allowed = false
        for _, j in ipairs(Config.RequiredJob) do
            if pj == j then allowed = true break end
        end
        if not allowed then
            TriggerClientEvent("QBCore:Notify", source, "You don't have the required job to start this.", "error")
            return
        end
    end

    -- Require fake papers
    local item = Player.Functions.GetItemByName(Config.RequiredItem)
    if not item then
        TriggerClientEvent("QBCore:Notify", source, "You need Fake Papers (" .. Config.RequiredItemImage .. ") to start this job!", "error")
        return
    end

    -- Assign cargo + delivery
    local cargo = Config.CargoTypes[math.random(#Config.CargoTypes)]
    local delivery = Config.DeliveryPoints[math.random(#Config.DeliveryPoints)]

    if Config.SQLPersistence then
        MySQL.insert('INSERT INTO transporter_jobs (player_id, vehicle_plate, cargo_type, status) VALUES (?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            "UNKNOWN",
            cargo.prop,
            'active'
        })
    end

    TriggerClientEvent("QBCore:Notify", source, "Pickup cargo: " .. cargo.label, "success")
    TriggerClientEvent("gcore:transporter:assignJob", source, cargo, delivery)
end)
