-- Admin commands
RegisterCommand("callconvoy", function(source, args)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local preset = args[1] or "zancudo" -- default spawn preset
    TriggerClientEvent("convoy:spawn", -1, coords, preset)
end, true)

RegisterCommand("despawnconvoy", function(source)
    TriggerClientEvent("convoy:despawn", -1)
end, true)
