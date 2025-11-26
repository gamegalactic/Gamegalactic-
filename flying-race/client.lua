local raceActive = false
local checkpoints = {}
local currentCheckpoint = 1
local raceStartTime = 0
local selectedRoute = nil

local raceRoutes = {
    ["LSIA Loop"] = {
        vector3(-1145.0, -2865.0, 100.0),
        vector3(-1200.0, -2800.0, 150.0),
        vector3(-1250.0, -2900.0, 200.0),
        vector3(-1145.0, -2865.0, 100.0)
    },
    ["Vinewood Dash"] = {
        vector3(600.0, 1000.0, 200.0),
        vector3(700.0, 1100.0, 250.0),
        vector3(800.0, 1200.0, 300.0),
        vector3(600.0, 1000.0, 200.0)
    },
    ["Cartel Skies"] = {
        vector3(1452.14, 111.96, 200.0),
        vector3(1500.0, 200.0, 250.0),
        vector3(1600.0, 300.0, 300.0),
        vector3(1700.0, 400.0, 350.0),
        vector3(1800.0, 500.0, 400.0)
    }
}

local function isAircraft(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false end
    local class = GetVehicleClass(veh)
    return class == 15 or class == 16
end

local function createCheckpoint(index)
    local pos = selectedRoute[index]
    local checkpoint = CreateCheckpoint(47, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 10.0, 0, 153, 255, 150, 0)
    SetCheckpointCylinderHeight(checkpoint, 10.0, 10.0, 10.0)
    return checkpoint
end

local function clearCheckpoints()
    for _, cp in pairs(checkpoints) do
        if cp then DeleteCheckpoint(cp) end
    end
    checkpoints = {}
end

local function GetCurrentRouteName()
    for name, route in pairs(raceRoutes) do
        if route == selectedRoute then return name end
    end
    return "Unknown"
end

local function startFlyingRace()
    if raceActive then
        print("[flying-race] Race already active")
        return
    end

    local ped = PlayerPedId()
    if not isAircraft(ped) then
        TriggerEvent("chat:addMessage", {
            args = { "[Flying Race]", "You must be in an aircraft to start the race!" }
        })
        return
    end

    raceActive = true
    currentCheckpoint = 1
    raceStartTime = GetGameTimer()

    print("[flying-race] Race started!")
    checkpoints[currentCheckpoint] = createCheckpoint(currentCheckpoint)

    CreateThread(function()
        while raceActive do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local target = selectedRoute[currentCheckpoint]

            if #(playerCoords - target) < 15.0 then
                DeleteCheckpoint(checkpoints[currentCheckpoint])
                currentCheckpoint += 1

                if selectedRoute[currentCheckpoint] then
                    checkpoints[currentCheckpoint] = createCheckpoint(currentCheckpoint)
                    print("[flying-race] Checkpoint reached:", currentCheckpoint - 1)
                else
                    local raceTime = (GetGameTimer() - raceStartTime) / 1000.0
                    TriggerEvent("chat:addMessage", {
                        args = { "[Flying Race]", "Finished in " .. raceTime .. " seconds!" }
                    })
                    print("[flying-race] Race complete! Time:", raceTime, "seconds")

                    TriggerServerEvent("flyingrace:submitTime", GetPlayerName(PlayerId()), raceTime, GetCurrentRouteName())

                    clearCheckpoints()
                    raceActive = false
                end
            end
            Wait(500)
        end
    end)
end

RegisterCommand("selectrace", function()
    local options = {}
    for name, _ in pairs(raceRoutes) do
        table.insert(options, {
            label = name,
            value = name
        })
    end

    lib.registerContext({
        id = 'race_selector',
        title = 'Select Flying Race',
        options = options,
        onSelect = function(data)
            selectedRoute = raceRoutes[data.value]
            TriggerEvent("chat:addMessage", {
                args = { "[Flying Race]", "Selected route: " .. data.value .. ". Press F7 to start!" }
            })
        end
    })

    lib.showContext('race_selector')
end, false)

RegisterCommand("startrace", function()
    if not selectedRoute then
        TriggerEvent("chat:addMessage", {
            args = { "[Flying Race]", "Select a route first using /selectrace" }
        })
        return
    end
    startFlyingRace()
end, false)

RegisterKeyMapping("selectrace", "Select Flying Race", "keyboard", "F6")
RegisterKeyMapping("startrace", "Start Flying Race", "keyboard", "F7")
