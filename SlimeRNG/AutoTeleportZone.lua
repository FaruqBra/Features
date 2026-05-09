--[[
    YourHub - Features/SlimeRNG/AutoTeleportZone.lua
    AutoTeleportZone: teleport ke zone tertentu.
    Interval 3 detik.
]]

local workspace = game:GetService("Workspace")

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Utilities = require(script.Parent.Parent.Parent.Core.Utilities)
local Notifications = require(script.Parent.Parent.Universal.Notifications)

local AutoTeleportZone = {}
local _initialized = false
local _lastTP = 0

-- ============================================================
-- Cari spawn point zona tertentu
-- ============================================================
local function findZoneSpawn(zoneNumber)
    -- Cari di workspace — sesuaikan dengan struktur map Slime RNG
    local zonesFolder = workspace:FindFirstChild("Zones")
                     or workspace:FindFirstChild("Map")
    if not zonesFolder then return nil end

    -- Coba berbagai nama yang mungkin digunakan game
    local zoneName = "Zone" .. zoneNumber
    local zone     = zonesFolder:FindFirstChild(zoneName)
                  or zonesFolder:FindFirstChild("Zone_" .. zoneNumber)

    if zone then
        local spawn = zone:FindFirstChild("SpawnPoint")
                   or zone:FindFirstChild("Spawn")
                   or zone:FindFirstChildWhichIsA("BasePart")
        return spawn
    end

    return nil
end

local function teleportZoneTick()
    if not Flags.AutoTeleportZone then return end

    local now = tick()
    if now - _lastTP < 3 then return end
    _lastTP = now

    local targetZone = Flags.AutoTeleportZone_Target or 1
    local spawnPart  = findZoneSpawn(targetZone)

    if spawnPart then
        local success = Utilities.TeleportToPart(spawnPart, 5)
        if success then
            Notifications.Info(
                "AutoTeleportZone",
                "Teleport ke Zone " .. targetZone,
                "success",
                1.5
            )
        end
    end
end

function AutoTeleportZone.Init()
    if _initialized then return end
    Scheduler.AddTask("AutoTeleportZone_Tick", teleportZoneTick, 3.0)
    _initialized = true
    print("[AutoTeleportZone] ✓ Diinisialisasi.")
end

function AutoTeleportZone.Destroy()
    Scheduler.RemoveTask("AutoTeleportZone_Tick")
    _initialized = false
end

return AutoTeleportZone
