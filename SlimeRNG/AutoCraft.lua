--[[
    YourHub - Features/SlimeRNG/AutoCraft.lua

    AutoCraft: fire Craft remote untuk crafting slime.
    Interval 5 detik (crafting tidak perlu cepat).
]]

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Remotes   = require(script.Parent.Parent.Parent.Core.Remotes)
local Notifications = require(script.Parent.Parent.Universal.Notifications)

local AutoCraft = {}
local _initialized = false

local function craftTick()
    if not Flags.AutoCraft then return end

    local target = Flags.AutoCraft_Target or "Crafty"

    local ok = pcall(function()
        Remotes.Fire("Craft", target)
    end)

    if ok then
        Notifications.Info("AutoCraft", "Mencoba craft: " .. target, "info", 1.5)
    end
end

function AutoCraft.Init()
    if _initialized then return end
    Scheduler.AddTask("AutoCraft_Tick", craftTick, 5.0)
    _initialized = true
    print("[AutoCraft] ✓ Diinisialisasi.")
end

function AutoCraft.Destroy()
    Scheduler.RemoveTask("AutoCraft_Tick")
    _initialized = false
end

return AutoCraft
