--[[
    YourHub - Features/Universal/ESP.lua

    ESP Universal — bekerja untuk semua game.
    BillboardGui per object.
    Update via Scheduler (TIDAK per Heartbeat frame).
    Max distance filter untuk performa mobile.
]]

local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")

local Flags       = require(script.Parent.Parent.Parent.Config.Flags)
local Settings    = require(script.Parent.Parent.Parent.Config.Settings)
local Constants   = require(script.Parent.Parent.Parent.Shared.Constants)
local Scheduler   = require(script.Parent.Parent.Parent.Core.Scheduler)
local Cache       = require(script.Parent.Parent.Parent.Core.Cache)
local Utilities   = require(script.Parent.Parent.Parent.Core.Utilities)
local Connections = require(script.Parent.Parent.Parent.Core.Connections)

local ESP = {}

-- ============================================================
-- INTERNAL
-- ============================================================
local _espObjects = {}  -- { obj = BillboardGui }
local _initialized = false

-- ============================================================
-- CREATE BILLBOARD
-- ============================================================
local function createBillboard(obj, label)
    -- Hapus billboard lama jika ada
    local existing = obj:FindFirstChild("YH_ESP")
    if existing then existing:Destroy() end

    local T = Settings.ESP

    local billboard = Instance.new("BillboardGui")
    billboard.Name          = "YH_ESP"
    billboard.Size          = UDim2.new(0, 0, 0, 40)
    billboard.StudsOffset   = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop   = true
    billboard.MaxDistance   = T.MaxDistance or Constants.ESP.MAX_DISTANCE
    billboard.Parent        = obj

    -- Name text
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size              = UDim2.new(0, 120, 0, 18)
    nameLabel.Position          = UDim2.new(0.5, -60, 0, 0)
    nameLabel.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
    nameLabel.BackgroundTransparency = 0.4
    nameLabel.Text              = label
    nameLabel.Font              = Enum.Font.GothamBold
    nameLabel.TextSize          = 12
    nameLabel.TextColor3        = T.TextColor or Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent            = billboard
    Instance.new("UICorner", nameLabel).CornerRadius = UDim.new(0, 4)

    -- Distance text
    local distLabel = Instance.new("TextLabel")
    distLabel.Name              = "DistLabel"
    distLabel.Size              = UDim2.new(0, 80, 0, 14)
    distLabel.Position          = UDim2.new(0.5, -40, 0, 20)
    distLabel.BackgroundTransparency = 1
    distLabel.Text              = "?"
    distLabel.Font              = Enum.Font.Gotham
    distLabel.TextSize          = 10
    distLabel.TextColor3        = Color3.fromRGB(180, 180, 180)
    distLabel.Parent            = billboard

    return billboard
end

-- ============================================================
-- REMOVE BILLBOARD
-- ============================================================
local function removeBillboard(obj)
    local billboard = obj:FindFirstChild("YH_ESP")
    if billboard then billboard:Destroy() end
end

-- ============================================================
-- UPDATE ESP OBJECTS
-- ============================================================
local function updateESP()
    if not Flags.ESP then
        -- Hapus semua ESP jika disabled
        if next(_espObjects) then
            for obj, _ in pairs(_espObjects) do
                pcall(removeBillboard, obj)
            end
            _espObjects = {}
        end
        return
    end

    local playerPos = Utilities.GetPosition()
    local maxDist   = Constants.ESP.MAX_DISTANCE

    -- ESP untuk Mobs
    if Flags.ESP_ShowMobs then
        local mobs = Cache.Get("Mobs")
        local currentMobs = {}

        for _, mob in ipairs(mobs) do
            if mob and mob.Parent then
                currentMobs[mob] = true
                if not _espObjects[mob] then
                    local name = mob.Name or "Mob"
                    local billboard = createBillboard(mob, name)
                    _espObjects[mob] = billboard
                end

                -- Update distance
                local pos = Utilities.GetModelPosition(mob)
                if pos then
                    local dist = (pos - playerPos).Magnitude
                    if dist <= maxDist then
                        local billboard = _espObjects[mob]
                        if billboard then
                            local distLabel = billboard:FindFirstChild("DistLabel")
                            if distLabel then
                                distLabel.Text = math.floor(dist) .. " studs"
                            end
                        end
                    end
                end
            end
        end

        -- Hapus ESP dari mobs yang sudah tidak ada
        for obj, _ in pairs(_espObjects) do
            if not currentMobs[obj] then
                pcall(removeBillboard, obj)
                _espObjects[obj] = nil
            end
        end
    end

    -- ESP untuk Drops
    if Flags.ESP_ShowDrops then
        local drops = Cache.Get("Drops")
        for _, drop in ipairs(drops) do
            if drop and drop.Parent and not _espObjects[drop] then
                local name = drop.Name or "Drop"
                local billboard = createBillboard(drop, "💎 " .. name)
                _espObjects[drop] = billboard
            end
        end
    end
end

-- ============================================================
-- CLEANUP
-- ============================================================
local function cleanupESP()
    for obj, _ in pairs(_espObjects) do
        pcall(removeBillboard, obj)
    end
    _espObjects = {}
end

-- ============================================================
-- INIT
-- ============================================================
function ESP.Init()
    if _initialized then return end

    -- Register ke scheduler — update setiap 0.1 detik
    -- BUKAN per Heartbeat frame
    Scheduler.AddTask("ESP_Update", function()
        updateESP()
    end, Constants.Intervals and Constants.Intervals.FAST or 0.1)

    _initialized = true
    print("[ESP] ✓ Diinisialisasi.")
end

-- ============================================================
-- DESTROY
-- ============================================================
function ESP.Destroy()
    cleanupESP()
    Scheduler.RemoveTask("ESP_Update")
    _initialized = false
end

return ESP
