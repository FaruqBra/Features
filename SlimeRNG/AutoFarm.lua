--[[
    YourHub - Features/SlimeRNG/AutoFarm.lua

    AutoFarm untuk Slime RNG.
    - Gunakan Cache untuk dapat mob list
    - Target mob terdekat
    - Teleport ke mob (via TP jika Flags.AutoFarm_UseTP)
    - Fire remote Attack
    - Scheduler-based: interval 0.25s
    - TIDAK ada while true do
    - TIDAK ada spam task.spawn
]]

local Flags       = require(script.Parent.Parent.Parent.Config.Flags)
local Settings    = require(script.Parent.Parent.Parent.Config.Settings)
local Constants   = require(script.Parent.Parent.Parent.Shared.Constants)
local Scheduler   = require(script.Parent.Parent.Parent.Core.Scheduler)
local Cache       = require(script.Parent.Parent.Parent.Core.Cache)
local Remotes     = require(script.Parent.Parent.Parent.Core.Remotes)
local Utilities   = require(script.Parent.Parent.Parent.Core.Utilities)
local Notifications = require(script.Parent.Parent.Universal.Notifications)

local AutoFarm = {}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local _initialized    = false
local _lastTeleport   = 0
local _currentTarget  = nil
local _farmCount      = 0

-- ============================================================
-- FARM LOGIC
-- ============================================================
local function farmTick()
    -- Cek flag
    if not Flags.AutoFarm then
        _currentTarget = nil
        return
    end

    -- Cek karakter
    if not Utilities.IsAlive() then return end

    local playerPos = Utilities.GetPosition()
    local farmRange = Flags.AutoFarm_Range or Constants.AutoFarm.DEFAULT_RANGE

    -- Dapatkan mob terdekat dari cache (TIDAK scan workspace)
    local nearestMob, nearestDist = Cache.GetNearest("Mobs", playerPos, farmRange)

    if not nearestMob then
        -- Tidak ada mob dalam range, coba range lebih besar
        nearestMob, nearestDist = Cache.GetNearest("Mobs", playerPos, math.huge)
        if not nearestMob then
            return  -- Tidak ada mob sama sekali
        end
    end

    -- Cek apakah mob masih valid
    if not nearestMob.Parent then
        _currentTarget = nil
        return
    end

    _currentTarget = nearestMob

    -- Teleport ke mob (cooldown prevent spam)
    local now = tick()
    if Flags.AutoFarm_UseTP then
        local tpCooldown = Constants.AutoFarm.TELEPORT_COOLDOWN or 0.3
        if now - _lastTeleport >= tpCooldown then
            local mobPos = Utilities.GetModelPosition(nearestMob)
            if mobPos then
                Utilities.Teleport(mobPos, 3)
                _lastTeleport = now
            end
        end
    end

    -- Attack mob via remote
    -- Sesuaikan parameter dengan remote Attack di game
    local attackRemote = Remotes.Get("Attack")
    if attackRemote then
        -- Coba fire attack
        local ok = pcall(function()
            attackRemote:FireServer(nearestMob)
        end)
        if ok then
            _farmCount = _farmCount + 1
            -- Debug setiap 100 hits
            if _farmCount % 100 == 0 then
                print("[AutoFarm] Total hits: " .. _farmCount)
            end
        end
    else
        -- Fallback: HumanoidRootPart touch attack (jika no remote)
        local humanoid = nearestMob:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            -- Pastikan sudah dekat
            local mobPos = Utilities.GetModelPosition(nearestMob)
            if mobPos then
                local dist = (playerPos - mobPos).Magnitude
                if dist <= 8 then
                    -- Lakukan basic attack via character tool jika ada
                    local char      = Utilities.GetCharacter()
                    local tool      = char and char:FindFirstChildOfClass("Tool")
                    local toolRemote = tool and tool:FindFirstChildOfClass("RemoteEvent")
                    if toolRemote then
                        pcall(function() toolRemote:FireServer(mobPos) end)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================
function AutoFarm.Init()
    if _initialized then return end

    -- Register ke scheduler — 0.25s interval
    Scheduler.AddTask("AutoFarm_Tick", farmTick, 0.25)

    _initialized = true
    Notifications.Info("AutoFarm", "AutoFarm siap digunakan.", "info", 2)
    print("[AutoFarm] ✓ Diinisialisasi.")
end

-- ============================================================
-- GET STATS (untuk debug/UI)
-- ============================================================
function AutoFarm.GetStats()
    return {
        Active  = Flags.AutoFarm,
        Target  = _currentTarget and _currentTarget.Name or "None",
        Hits    = _farmCount,
    }
end

-- ============================================================
-- DESTROY
-- ============================================================
function AutoFarm.Destroy()
    Scheduler.RemoveTask("AutoFarm_Tick")
    _currentTarget = nil
    _farmCount     = 0
    _initialized   = false
end

return AutoFarm
