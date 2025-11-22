-- server.lua
-- Simple join/leave broadcast script for FiveM/QB-Core

-- Player connecting (before they fully load in)
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local message = ("?? Welcome %s to the server! ??"):format(playerName)
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 0, 255, 0 }, -- green
        multiline = true,
        args = { "Server", message }
    })
end)

-- Player dropped (when they leave/disconnect)
AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerName = GetPlayerName(src)
    local message = ("?? %s has left the server. Reason: %s"):format(playerName, reason)
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 0, 0 }, -- red
        multiline = true,
        args = { "Server", message }
    })
end)
