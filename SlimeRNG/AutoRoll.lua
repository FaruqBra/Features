--[[
    YourHub - Features/SlimeRNG/AutoRoll.lua

    AutoRoll: fire Roll remote berulang.
    Scheduler-based dengan configurable delay.
    Ringan, mobile optimized.
]]

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Constants = require(script.Parent.Parent.Parent.Shared.Constants)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Remotes   = require(script.Parent.Parent.Parent.Core.Remotes)
local Utilities = require(script.Parent.Parent.Parent.Core.Utilities)

local AutoRoll = {}

-- ============================================================
-- INTERNAL
-- ============================================================
local _initialized = false
local _rollCount   = 0
local _lastRoll    = 0

-- ============================================================
-- ROLL TICK
-- ============================================================
local function rollTick()
    if not Flags.AutoRoll then return end
    if not Utilities.IsAlive() then return end

    local delay = Flags.AutoRoll_Delay or Constants.AutoRoll.DEFAULT_DELAY
    local now   = tick()

    -- Throttle berdasarkan delay yang dikonfigurasi user
    if now - _lastRoll < delay then return end
    _lastRoll = now

    -- Fire Roll remote
    local ok, err = pcall(function()
        Remotes.Fire("Roll")
    end)

    if ok then
        _rollCount = _rollCount + 1
        -- Log setiap 500 rolls
        if _rollCount % 500 == 0 then
            print("[AutoRoll] Total rolls: " .. _rollCount)
        end
    else
        warn("[AutoRoll] Gagal roll: " .. tostring(err))
    end
end

-- ============================================================
-- INIT
-- ============================================================
function AutoRoll.Init()
    if _initialized then return end

    -- Register ke scheduler
    -- Interval scheduler lebih cepat dari delay user agar presisi
    Scheduler.AddTask("AutoRoll_Tick", rollTick, 0.05)

    _initialized = true
    print("[AutoRoll] ✓ Diinisialisasi.")
end

function AutoRoll.GetStats()
    return {
        Active = Flags.AutoRoll,
        Rolls  = _rollCount,
        Delay  = Flags.AutoRoll_Delay,
    }
end

function AutoRoll.Destroy()
    Scheduler.RemoveTask("AutoRoll_Tick")
    _rollCount   = 0
    _initialized = false
end

return AutoRoll
