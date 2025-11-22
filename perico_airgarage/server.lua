local QBCore = exports['qb-core']:GetCoreObject()

-- Store plane (upsert by plate)
RegisterNetEvent('perico_airgarage:storePlane', function(vehProps)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not vehProps or not vehProps.plate then return end

    local citizenid = Player.PlayerData.citizenid
    local plate = vehProps.plate
    local model = vehProps.model or vehProps.modelHash or tostring(GetEntityModel(GetVehiclePedIsIn(GetPlayerPed(src), false)))

    exports.oxmysql:insert(
        [[
            INSERT INTO perico_planes (citizenid, plate, model, props, is_stored)
            VALUES (?, ?, ?, ?, 1)
            ON DUPLICATE KEY UPDATE
              citizenid = VALUES(citizenid),
              model = VALUES(model),
              props = VALUES(props),
              is_stored = VALUES(is_stored)
        ]],
        { citizenid, plate, model, json.encode(vehProps) }
    )

    TriggerClientEvent('QBCore:Notify', src, 'Plane stored in Perico hangar!', 'success')
end)

-- Retrieve plane by plate
RegisterNetEvent('perico_airgarage:retrievePlane', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not plate then return end

    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:fetch(
        'SELECT * FROM perico_planes WHERE citizenid = ? AND plate = ? AND is_stored = 1 LIMIT 1',
        { citizenid, plate },
        function(result)
            if result and result[1] then
                local props = json.decode(result[1].props)
                TriggerClientEvent('perico_airgarage:spawnPlane', src, props)
                exports.oxmysql:update('UPDATE perico_planes SET is_stored = 0 WHERE plate = ?', { plate })
            else
                TriggerClientEvent('QBCore:Notify', src, 'No plane found in Perico hangar with that plate!', 'error')
            end
        end
    )
end)
