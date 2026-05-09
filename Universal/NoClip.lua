--[[
    YourHub - Features/Universal/NoClip.lua
    NoClip: set CanCollide = false pada character parts.
    Scheduler-based. Ringan.
]]

local Players  = game:GetService("Players")

local Flags    = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Connections = require(script.Parent.Parent.Parent.Core.Connections)
local Utilities = require(script.Parent.Parent.Parent.Core.Utilities)

local NoClip = {}

local _initialized = false

-- ============================================================
-- NOCLIP UPDATE
-- ============================================================
local function noClipUpdate()
    local char = Utilities.GetCharacter()
    if not char then return end

    if Flags.NoClip then
        -- Nonaktifkan collision semua parts
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        -- Kembalikan collision HumanoidRootPart
        -- Part lain dibiarkan karena HRP yang paling krusial
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CanCollide = false  -- HRP tetap false agar tidak stuck
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================
function NoClip.Init()
    if _initialized then return end

    -- Update setiap 0.1 detik
    Scheduler.AddTask("NoClip_Update", noClipUpdate, 0.1)

    -- Re-apply saat respawn
    local conn = Players.LocalPlayer.CharacterAdded:Connect(function()
        -- Reset state
        task.wait(0.5)
        if Flags.NoClip then
            noClipUpdate()
        end
    end)
    Connections.Add("NoClip_CharAdded", conn)

    _initialized = true
    print("[NoClip] ✓ Diinisialisasi.")
end

function NoClip.Destroy()
    Scheduler.RemoveTask("NoClip_Update")
    Connections.Remove("NoClip_CharAdded")
    -- Restore collision
    local char = Utilities.GetCharacter()
    if char then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    _initialized = false
end

return NoClip
