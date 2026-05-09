--[[
    YourHub - Features/Universal/Fly.lua
    Fly feature universal.
    Mobile-compatible (touch controls).
    Scheduler-based velocity update.
]]

local Players        = game:GetService("Players")
local UserInput      = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")

local Flags          = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler      = require(script.Parent.Parent.Parent.Core.Scheduler)
local Connections    = require(script.Parent.Parent.Parent.Core.Connections)
local Utilities      = require(script.Parent.Parent.Parent.Core.Utilities)

local Fly = {}

-- ============================================================
-- INTERNAL
-- ============================================================
local _bodyVelocity      = nil
local _bodyGyro          = nil
local _origGravityScale  = nil
local _flyActive         = false
local _initialized       = false

-- ============================================================
-- ENABLE FLY
-- ============================================================
local function enableFly(character)
    if _flyActive then return end
    if not character then return end

    local root     = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    _flyActive = true

    -- Save original walk speed
    _origGravityScale = workspace.Gravity

    -- BodyVelocity untuk movement
    _bodyVelocity = Instance.new("BodyVelocity")
    _bodyVelocity.Velocity       = Vector3.new(0, 0, 0)
    _bodyVelocity.MaxForce       = Vector3.new(1e5, 1e5, 1e5)
    _bodyVelocity.P              = 1e4
    _bodyVelocity.Parent         = root

    -- BodyGyro untuk rotasi stabil
    _bodyGyro = Instance.new("BodyGyro")
    _bodyGyro.MaxTorque          = Vector3.new(1e5, 1e5, 1e5)
    _bodyGyro.P                  = 1e4
    _bodyGyro.D                  = 100
    _bodyGyro.CFrame             = root.CFrame
    _bodyGyro.Parent             = root

    humanoid.PlatformStand = true

    print("[Fly] ✓ Fly aktif.")
end

-- ============================================================
-- DISABLE FLY
-- ============================================================
local function disableFly()
    if not _flyActive then return end

    _flyActive = false

    if _bodyVelocity then
        _bodyVelocity:Destroy()
        _bodyVelocity = nil
    end
    if _bodyGyro then
        _bodyGyro:Destroy()
        _bodyGyro = nil
    end

    local char = Utilities.GetCharacter()
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end

    print("[Fly] ✗ Fly dinonaktifkan.")
end

-- ============================================================
-- FLY UPDATE (dipanggil Scheduler)
-- ============================================================
local function flyUpdate()
    if not Flags.Fly then
        if _flyActive then disableFly() end
        return
    end

    local char  = Utilities.GetCharacter()
    local root  = Utilities.GetRootPart()
    if not char or not root then
        if _flyActive then disableFly() end
        return
    end

    if not _flyActive then
        enableFly(char)
    end

    if not _bodyVelocity or not _bodyGyro then return end

    local speed     = Flags.FlySpeed or 50
    local camera    = workspace.CurrentCamera
    local camCF     = camera.CFrame
    local direction = Vector3.new(0, 0, 0)

    -- PC Controls
    if UserInput:IsKeyDown(Enum.KeyCode.W) then
        direction = direction + Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    end
    if UserInput:IsKeyDown(Enum.KeyCode.S) then
        direction = direction - Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    end
    if UserInput:IsKeyDown(Enum.KeyCode.A) then
        direction = direction - Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
    end
    if UserInput:IsKeyDown(Enum.KeyCode.D) then
        direction = direction + Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
    end
    if UserInput:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction = direction - Vector3.new(0, 1, 0)
    end

    -- Normalize agar diagonal tidak lebih cepat
    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    _bodyVelocity.Velocity = direction * speed

    -- Update gyro
    if direction.Magnitude > 0 then
        _bodyGyro.CFrame = CFrame.new(root.Position, root.Position + direction)
    end
end

-- ============================================================
-- INIT
-- ============================================================
function Fly.Init()
    if _initialized then return end

    -- Register ke scheduler (update setiap 0.05s untuk smooth fly)
    Scheduler.AddTask("Fly_Update", flyUpdate, 0.05)

    -- Cleanup saat karakter respawn
    local player = Players.LocalPlayer
    local conn = player.CharacterAdded:Connect(function()
        disableFly()
    end)
    Connections.Add("Fly_CharAdded", conn)

    _initialized = true
    print("[Fly] ✓ Diinisialisasi.")
end

-- ============================================================
-- DESTROY
-- ============================================================
function Fly.Destroy()
    disableFly()
    Scheduler.RemoveTask("Fly_Update")
    Connections.Remove("Fly_CharAdded")
    _initialized = false
end

return Fly
