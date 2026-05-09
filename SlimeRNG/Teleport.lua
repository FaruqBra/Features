--[[
    YourHub - Features/Universal/Teleport.lua
    Universal teleport utility feature.
    TP ke nearest drop atau ke cursor position.
]]

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Cache     = require(script.Parent.Parent.Parent.Core.Cache)
local Utilities = require(script.Parent.Parent.Parent.Core.Utilities)

local Teleport = {}
local _initialized = false

local function teleportTick()
    if not Flags.Teleport then return end

    -- Auto TP ke drop terdekat
    local playerPos = Utilities.GetPosition()
    local nearestDrop, dist = Cache.GetNearest("Drops", playerPos, 100)

    if nearestDrop and dist < 100 then
        local pos = Utilities.GetModelPosition(nearestDrop)
        if pos then
            Utilities.Teleport(pos, 2)
        end
    end
end

function Teleport.Init()
    if _initialized then return end
    Scheduler.AddTask("Teleport_Tick", teleportTick, 0.5)
    _initialized = true
    print("[Teleport] ✓ Diinisialisasi.")
end

function Teleport.Destroy()
    Scheduler.RemoveTask("Teleport_Tick")
    _initialized = false
end

return Teleport
