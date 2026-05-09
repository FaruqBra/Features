--[[
    YourHub - Features/SlimeRNG/AutoPotion.lua

    AutoPotion: pakai potion saat HP di bawah threshold.
    Scheduler-based. Interval 2 detik (tidak perlu cepat).
]]

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Constants = require(script.Parent.Parent.Parent.Shared.Constants)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Remotes   = require(script.Parent.Parent.Parent.Core.Remotes)
local Utilities = require(script.Parent.Parent.Parent.Core.Utilities)
local Notifications = require(script.Parent.Parent.Universal.Notifications)

local AutoPotion = {}

local _initialized = false
local _lastPotion  = 0

-- ============================================================
-- POTION TICK
-- ============================================================
local function potionTick()
    if not Flags.AutoPotion then return end

    local humanoid = Utilities.GetHumanoid()
    if not humanoid then return end

    -- Cek HP
    local hpPercent = (humanoid.Health / humanoid.MaxHealth) * 100
    local threshold = Flags.AutoPotion_MinHP or 50

    if hpPercent <= threshold then
        local now = tick()
        if now - _lastPotion < 1.0 then return end  -- cooldown 1 detik
        _lastPotion = now

        local ok = pcall(function()
            Remotes.Fire("Potion")
        end)

        if ok then
            Notifications.Info(
                "Auto Potion",
                "Potion digunakan! HP: " .. math.floor(hpPercent) .. "%",
                "success",
                2
            )
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================
function AutoPotion.Init()
    if _initialized then return end

    -- Check setiap 2 detik (tidak perlu cepat)
    Scheduler.AddTask("AutoPotion_Tick", potionTick, 2.0)

    _initialized = true
    print("[AutoPotion] ✓ Diinisialisasi.")
end

function AutoPotion.Destroy()
    Scheduler.RemoveTask("AutoPotion_Tick")
    _initialized = false
end

return AutoPotion
