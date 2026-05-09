--[[
    YourHub - Features/Universal/Notifications.lua
    In-game notification system.
    Mobile-friendly. Minimal tween.
    Max 3 notif sekaligus.
]]

local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")

local Constants    = require(script.Parent.Parent.Parent.Shared.Constants)
local Theme        = require(script.Parent.Parent.Parent.UI.Theme)

local Notifications = {}

-- ============================================================
-- INTERNAL STATE
-- ============================================================
local _container   = nil
local _queue       = {}
local _active      = {}  -- notif yang sedang tampil
local _initialized = false

-- ============================================================
-- INIT
-- ============================================================
function Notifications.Init()
    if _initialized then return end

    local T = Theme.Get()

    -- Container untuk semua notif
    _container = Instance.new("ScreenGui")
    _container.Name           = "YourHub_Notifs"
    _container.ResetOnSpawn   = false
    _container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _container.DisplayOrder   = 1000
    _container.Parent         = CoreGui

    local frame = Instance.new("Frame")
    frame.Name           = "NotifFrame"
    frame.Size           = UDim2.new(0, 280, 1, 0)
    frame.Position       = UDim2.new(1, -290, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Parent         = _container

    local layout = Instance.new("UIListLayout")
    layout.SortOrder      = Enum.SortOrder.LayoutOrder
    layout.Padding        = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    layout.Parent         = frame

    -- Padding dari bawah
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.Parent        = frame

    _container._frame = frame

    _initialized = true
    print("[Notifications] ✓ Inisialisasi selesai.")
end

-- ============================================================
-- SHOW NOTIFICATION
-- Types: "info", "success", "error", "warning"
-- ============================================================
function Notifications.Show(title, message, notifType, duration)
    if not _initialized then Notifications.Init() end

    notifType = notifType or "info"
    duration  = duration  or Constants.Notification.DEFAULT_DURATION

    -- Max 3 notif aktif
    if #_active >= Constants.Notification.MAX_VISIBLE then
        table.remove(_active, 1):Destroy()
    end

    local T        = Theme.Get()
    local C        = Constants.Colors
    local accentColor = notifType == "success" and C.SUCCESS
                     or notifType == "error"   and C.ERROR
                     or notifType == "warning"  and C.WARNING
                     or C.INFO

    -- Notif frame
    local notif = Instance.new("Frame")
    notif.Name             = "Notif"
    notif.Size             = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = T.NotifBg
    notif.BorderSizePixel  = 0
    notif.BackgroundTransparency = 0.05
    notif.Parent           = _container._frame
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

    -- Accent bar kiri
    local accentBar = Instance.new("Frame")
    accentBar.Size             = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = accentColor
    accentBar.BorderSizePixel  = 0
    accentBar.Parent           = notif
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 4)

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size             = UDim2.new(1, -16, 0, 22)
    titleLabel.Position         = UDim2.new(0, 12, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text             = title
    titleLabel.Font             = Theme.Fonts.Bold
    titleLabel.TextSize         = Theme.TextSizes.Body
    titleLabel.TextColor3       = accentColor
    titleLabel.TextXAlignment   = Enum.TextXAlignment.Left
    titleLabel.Parent           = notif

    -- Message
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size               = UDim2.new(1, -16, 0, 20)
    msgLabel.Position           = UDim2.new(0, 12, 0, 28)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text               = message
    msgLabel.Font               = Theme.Fonts.Regular
    msgLabel.TextSize           = Theme.TextSizes.Small
    msgLabel.TextColor3         = T.TextSecondary
    msgLabel.TextXAlignment     = Enum.TextXAlignment.Left
    msgLabel.TextWrapped        = true
    msgLabel.Parent             = notif

    -- Fade in
    notif.BackgroundTransparency = 1
    TweenService:Create(notif, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.05
    }):Play()

    table.insert(_active, notif)

    -- Auto dismiss
    task.delay(duration, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.35, function()
                if notif and notif.Parent then
                    notif:Destroy()
                end
            end)
            -- Remove dari active list
            local idx = table.find(_active, notif)
            if idx then table.remove(_active, idx) end
        end
    end)
end

-- ============================================================
-- SHORTHAND METHODS
-- ============================================================
function Notifications.Info(title, msg, duration)
    Notifications.Show(title, msg, "info", duration)
end

function Notifications.Success(title, msg, duration)
    Notifications.Show(title, msg, "success", duration)
end

function Notifications.Error(title, msg, duration)
    Notifications.Show(title, msg, "error", duration)
end

function Notifications.Warning(title, msg, duration)
    Notifications.Show(title, msg, "warning", duration)
end

-- ============================================================
-- DESTROY
-- ============================================================
function Notifications.Destroy()
    if _container then
        _container:Destroy()
        _container   = nil
        _active      = {}
        _initialized = false
    end
end

return Notifications
