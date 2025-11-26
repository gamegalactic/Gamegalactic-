-- Convoy Config
local convoyConfig = {
    vehicles = {"crusader", "barracks", "mesa"},
    pedModel = "s_m_y_marine_01",
    convoySize = 8,
    spacing = 8.0,          -- meters between vehicles
    formation = "column",   -- "column" or "line"
    speed = 13.0,           -- ~30–40 km/h
    passengersPerVeh = 4,   -- number of passengers per vehicle (excluding driver)
    policeModel = "police2",
    copModel = "s_m_y_cop_01",
    policeFrontOffset = 15.0, -- meters ahead of spawn heading
    policeRearOffset  = -15.0, -- meters behind
    arrivalRadius = 20.0
}

local convoyVehicles, convoyPeds, convoyBlips = {}, {}, {}
local escortVehicles, escortPeds = {}, {}
local arrivalThreadActive = false

-- Utils
local function loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return hash
end

local function safeSetVehicleOnGround(veh)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehRadioStation(veh, "OFF")
    SetVehicleRadioEnabled(veh, false)
end

local function addLeadBlip(veh)
    local blip = AddBlipForEntity(veh)
    SetBlipSprite(blip, 470)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.0)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Army Convoy")
    EndTextCommandSetBlipName(blip)
    table.insert(convoyBlips, blip)
end

local function armSoldier(ped)
    local rifle = GetHashKey("WEAPON_CARBINERIFLE")
    GiveWeaponToPed(ped, rifle, 120, false, true)
    SetCurrentPedWeapon(ped, rifle, true)
    SetPedAccuracy(ped, 60)
    SetPedCombatRange(ped, 2)      -- medium
    SetPedCombatMovement(ped, 2)   -- defensive
    SetPedCombatAttributes(ped, 46, true) -- always fight
    SetPedCombatAttributes(ped, 2, true)  -- use cover
    SetPedCombatAttributes(ped, 5, true)  -- engage armed enemies
end

local function makeFriendlyToPlayer(ped, playerPed)
    local playerGroup = GetPedGroupIndex(playerPed)
    SetPedAsGroupMember(ped, playerGroup)
    SetPedNeverLeavesGroup(ped, true)
    SetPedRelationshipGroupHash(ped, GetHashKey("ARMY"))
    SetRelationshipBetweenGroups(1, GetHashKey("PLAYER"), GetHashKey("ARMY"))
    SetRelationshipBetweenGroups(1, GetHashKey("ARMY"), GetHashKey("PLAYER"))
end

local function forceExitVehicle(ped)
    ClearPedTasksImmediately(ped)
    TaskLeaveAnyVehicle(ped, 4160, 0)
    Wait(500)
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            local pos = GetEntityCoords(veh)
            SetEntityCoords(ped, pos.x + 2.0, pos.y, pos.z)
        end
    end
    ClearPedTasks(ped)
end

local function clearConvoyState()
    for _, ped in ipairs(convoyPeds) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    for _, veh in ipairs(convoyVehicles) do if DoesEntityExist(veh) then DeleteEntity(veh) end end
    for _, ped in ipairs(escortPeds) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    for _, veh in ipairs(escortVehicles) do if DoesEntityExist(veh) then DeleteEntity(veh) end end
    for _, blip in ipairs(convoyBlips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
    convoyVehicles, convoyPeds, convoyBlips, escortVehicles, escortPeds = {}, {}, {}, {}, {}
    arrivalThreadActive = false
end

-- Spawning helpers
local function spawnConvoyVehicle(i, spawnPoint, destCoords)
    local vehModelHash = loadModel(convoyConfig.vehicles[i] or convoyConfig.vehicles[1])
    local pedModelHash = loadModel(convoyConfig.pedModel)

    local headingRad = math.rad(spawnPoint.w)
    local offsetX, offsetY
    if convoyConfig.formation == "column" then
        offsetX = math.cos(headingRad) * (i * convoyConfig.spacing)
        offsetY = math.sin(headingRad) * (i * convoyConfig.spacing)
    else
        offsetX = math.cos(headingRad + math.pi/2) * (i * convoyConfig.spacing)
        offsetY = math.sin(headingRad + math.pi/2) * (i * convoyConfig.spacing)
    end

    local spawnX = spawnPoint.x - offsetX
    local spawnY = spawnPoint.y - offsetY
    local _, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnPoint.z + 10.0, 0)
    local z = (groundZ ~= 0) and groundZ or spawnPoint.z

    local veh = CreateVehicle(vehModelHash, spawnX, spawnY, z, spawnPoint.w, true, true)
    if not DoesEntityExist(veh) then return end
    safeSetVehicleOnGround(veh)
    table.insert(convoyVehicles, veh)

    -- Driver
    local driver = CreatePedInsideVehicle(veh, 4, pedModelHash, -1, true, true)
    if DoesEntityExist(driver) then
        SetEntityAsMissionEntity(driver, true, true)
        table.insert(convoyPeds, driver)
        armSoldier(driver)
    end

    -- Passengers (fill front passenger first, then others if available)
    local seatsAdded = 0
    local seats = {0, 1, 2} -- typical seats; adjust per vehicle if needed
    for _, seatIndex in ipairs(seats) do
        if seatsAdded >= convoyConfig.passengersPerVeh then break end
        local passenger = CreatePedInsideVehicle(veh, 4, pedModelHash, seatIndex, true, true)
        if DoesEntityExist(passenger) then
            table.insert(convoyPeds, passenger)
            armSoldier(passenger)
            seatsAdded = seatsAdded + 1
        end
    end

    -- Task independent drive to destination with X offset for spacing
    TaskVehicleDriveToCoord(driver, veh,
        destCoords.x - (i * convoyConfig.spacing),
        destCoords.y,
        destCoords.z,
        convoyConfig.speed, 0, vehModelHash, 786468, 1.0, true)

    if i == 1 then addLeadBlip(veh) end
end

-- Main spawn
RegisterNetEvent("convoy:spawn")
AddEventHandler("convoy:spawn", function(destCoords, preset)
    clearConvoyState()

    local spawnPresets = {
        arena   = vector4(-250.0, -200.0, 30.0, 90.0),
        zancudo = vector4(-2040.0, 3140.0, 32.0, 90.0),
        lsia    = vector4(-1034.0, -2733.0, 13.0, 330.0),
        sandy   = vector4(1740.0, 3250.0, 41.0, 120.0)
    }
    local defaultSpawn = spawnPresets.zancudo
    local spawnPoint = spawnPresets[preset] or defaultSpawn

    -- Convoy vehicles
    for i = 1, convoyConfig.convoySize do
        spawnConvoyVehicle(i, spawnPoint, destCoords)
    end

    -- Escorts (after convoy exists so we can reference first/last vehicles)
    spawnPoliceEscort(spawnPoint)

    TriggerEvent("chat:addMessage", { args = { "^2Convoy + police escorts spawned and en route!" } })

    -- Arrival monitor: wait for ALL convoy vehicles near destination
    if not arrivalThreadActive then
        arrivalThreadActive = true
        CreateThread(function()
            while arrivalThreadActive do
                Wait(1000)
                local allArrived = true
                for _, veh in ipairs(convoyVehicles) do
                    if DoesEntityExist(veh) then
                        local dist = #(GetEntityCoords(veh) - vector3(destCoords.x, destCoords.y, destCoords.z))
                        if dist > convoyConfig.arrivalRadius then
                            allArrived = false
                            break
                        end
                    end
                end
                if allArrived then
                    TriggerEvent("convoy:arrive")
                    arrivalThreadActive = false
                end
            end
        end)
    end
end)
-- Arrival: stop vehicles, force exit, arm + protect player
RegisterNetEvent("convoy:arrive")
AddEventHandler("convoy:arrive", function()
    local playerPed = PlayerPedId()

    -- Stop convoy vehicles
    for _, veh in ipairs(convoyVehicles) do
        if DoesEntityExist(veh) then
            SetVehicleHandbrake(veh, true)
            SetVehicleBrakeLights(veh, true)
            local driver = GetPedInVehicleSeat(veh, -1)
            if driver and DoesEntityExist(driver) then
                TaskVehicleTempAction(driver, veh, 27, 4000) -- hard brake
            end
        end
    end
    -- Stop escorts too
    for _, veh in ipairs(escortVehicles) do
        if DoesEntityExist(veh) then
            SetVehicleHandbrake(veh, true)
            SetVehicleBrakeLights(veh, true)
            -- keep sirens on for ambience
        end
    end
-- Convoy Stop + Formation Handler
function ConvoyStopFormation(convoyId, targetCoords)
    local convoy = Convoys[convoyId]
    if not convoy or not convoy.leadVehicle then return end

    local leadVeh = convoy.leadVehicle
    local leadDriver = convoy.drivers[1]
    ConvoyPostArrivalBehavior(convoyId)

    -- Detect arrival
    if #(GetEntityCoords(leadVeh) - targetCoords) < 10.0 then
        -- Clear lead driver tasks
        ClearPedTasks(leadDriver)
        SetDriveTaskCruiseSpeed(leadDriver, 0.0)
        SetVehicleForwardSpeed(leadVeh, 0.0)

        -- Formation repositioning
        local heading = GetEntityHeading(leadVeh)

        for i, veh in ipairs(convoy.vehicles) do
            if i > 1 then
                local offset = vector3(0.0, -8.0 * (i-1), 0.0) -- default line
                if convoy.formationType == "staggered" then
                    local side = (i % 2 == 0) and 3.0 or -3.0 -- alternate left/right
                    offset = vector3(side, -8.0 * math.floor((i-1)/2+1), 0.0)
                end

                local stopPos = GetOffsetFromEntityInWorldCoords(leadVeh, offset.x, offset.y, offset.z)

                ClearPedTasks(convoy.drivers[i])
                SetEntityCoords(veh, stopPos.x, stopPos.y, stopPos.z, false, false, false, true)
                SetEntityHeading(veh, heading)
                SetVehicleForwardSpeed(veh, 0.0)
            end
        end

        convoy.status = "Arrived"
        TriggerClientEvent("convoy:updateStatus", -1, convoyId, "Arrived")
    end
end

    Wait(2500)
-- Convoy Post-Arrival Behavior: Idle Guard Mode
function ConvoyPostArrivalBehavior(convoyId)
    local convoy = Convoys[convoyId]
    if not convoy then return end

    for i, veh in ipairs(convoy.vehicles) do
        local driver = convoy.drivers[i]
        if driver and DoesEntityExist(driver) then
            -- Make sure they stop driving
            ClearPedTasks(driver)
            SetVehicleForwardSpeed(veh, 0.0)

            -- Decide behavior: exit vehicle + guard
            TaskLeaveVehicle(driver, veh, 0)
            Citizen.Wait(1000) -- small delay so they’re clear of the car

            -- Idle guard mode: stand near vehicle, watch area
            TaskGuardCurrentPosition(driver, 15.0, 15.0, true)
        end
    end

    convoy.status = "Guarding"
    TriggerClientEvent("convoy:updateStatus", -1, convoyId, "Guarding")
end

    -- Deploy soldiers: force exit + arm + make friendly + follow/protect
    for _, ped in ipairs(convoyPeds) do
        if DoesEntityExist(ped) then
            forceExitVehicle(ped)
            armSoldier(ped)
            makeFriendlyToPlayer(ped, playerPed)
            TaskFollowToOffsetOfEntity(ped, playerPed, 0.0, -2.0, 0.0, 2.0, -1, 1.0, true)
        end
    end

    TriggerEvent("chat:addMessage", { args = { "^3Convoy arrived. Soldiers deployed, armed, and protecting the player." } })
end)
ConvoyMissionComplete(convoyId, "defended")
-- or
ConvoyMissionComplete(convoyId, "hijacked")

-- Cleanup
RegisterNetEvent("convoy:despawn")
AddEventHandler("convoy:despawn", function()
    clearConvoyState()
    TriggerEvent("chat:addMessage", { args = { "^1Convoy and escorts despawned." } })
end)
