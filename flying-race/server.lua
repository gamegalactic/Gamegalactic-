local leaderboardFile = 'leaderboard.json'
local leaderboard = {}

local function loadLeaderboard()
    local file = LoadResourceFile(GetCurrentResourceName(), leaderboardFile)
    if file then
        leaderboard = json.decode(file) or {}
    else
        leaderboard = {}
    end
end

local function saveLeaderboard()
    SaveResourceFile(GetCurrentResourceName(), leaderboardFile, json.encode(leaderboard, { indent = true }), -1)
end

RegisterNetEvent("flyingrace:submitTime", function(playerName, time, routeName)
    loadLeaderboard()

    leaderboard[routeName] = leaderboard[routeName] or {}
    local currentBest = leaderboard[routeName][playerName]

    if not currentBest or time < currentBest then
        leaderboard[routeName][playerName] = time
        print("[Flying Race] New best time for " .. playerName .. " on " .. routeName .. ": " .. time .. "s")
    else
        print("[Flying Race] " .. playerName .. " finished in " .. time .. "s (best: " .. currentBest .. "s)")
    end

    saveLeaderboard()
end)

RegisterCommand("showleaderboard", function(source, args)
    loadLeaderboard()
    print("=== Flying Race Leaderboard ===")
    for route, times in pairs(leaderboard) do
        print("Route: " .. route)
        for name, time in pairs(times) do
            print("  " .. name .. ": " .. time .. "s")
        end
    end
end, true)
