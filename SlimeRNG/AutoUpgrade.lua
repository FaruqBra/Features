--[[
    YourHub - Features/SlimeRNG/AutoUpgrade.lua
    AutoUpgrade: fire Upgrade remote untuk upgrade stats.
    Interval 3 detik.
]]

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Remotes   = require(script.Parent.Parent.Parent.Core.Remotes)

local AutoUpgrade = {}
local _initialized = false

local function upgradeTick()
    if not Flags.AutoUpgrade then return end

    local target = Flags.AutoUpgrade_Target or "Damage"
    pcall(function()
        Remotes.Fire("Upgrade", target)
    end)
end

function AutoUpgrade.Init()
    if _initialized then return end
    Scheduler.AddTask("AutoUpgrade_Tick", upgradeTick, 3.0)
    _initialized = true
    print("[AutoUpgrade] ✓ Diinisialisasi.")
end

function AutoUpgrade.Destroy()
    Scheduler.RemoveTask("AutoUpgrade_Tick")
    _initialized = false
end

return AutoUpgrade
