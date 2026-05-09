--[[
    YourHub - Features/SlimeRNG/AutoBuyZone.lua
    AutoBuyZone: otomatis beli zone berikutnya.
    Interval 5 detik.
]]

local Players   = game:GetService("Players")

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Remotes   = require(script.Parent.Parent.Parent.Core.Remotes)
local Notifications = require(script.Parent.Parent.Universal.Notifications)

local AutoBuyZone = {}
local _initialized = false
local _lastBuy = 0

local function buyZoneTick()
    if not Flags.AutoBuyZone then return end

    local now = tick()
    if now - _lastBuy < 5 then return end
    _lastBuy = now

    -- Coba beli zone berikutnya
    local ok = pcall(function()
        Remotes.Fire("BuyZone")
    end)

    if ok then
        Notifications.Info("AutoBuyZone", "Mencoba beli zone baru.", "info", 1.5)
    end
end

function AutoBuyZone.Init()
    if _initialized then return end
    Scheduler.AddTask("AutoBuyZone_Tick", buyZoneTick, 5.0)
    _initialized = true
    print("[AutoBuyZone] ✓ Diinisialisasi.")
end

function AutoBuyZone.Destroy()
    Scheduler.RemoveTask("AutoBuyZone_Tick")
    _initialized = false
end

return AutoBuyZone
