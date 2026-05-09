--[[
    YourHub - Features/SlimeRNG/AutoEquipBestPet.lua
    AutoEquipBestPet: auto equip pet dengan stat tertinggi.
    Interval 10 detik (tidak perlu sering).
]]

local Players   = game:GetService("Players")

local Flags     = require(script.Parent.Parent.Parent.Config.Flags)
local Scheduler = require(script.Parent.Parent.Parent.Core.Scheduler)
local Remotes   = require(script.Parent.Parent.Parent.Core.Remotes)

local AutoEquipBestPet = {}
local _initialized = false

-- ============================================================
-- Cari pet terbaik di inventory player
-- Logic ini perlu disesuaikan dengan struktur data Slime RNG
-- ============================================================
local function findBestPet()
    local player    = Players.LocalPlayer
    local inventory = player:FindFirstChild("Inventory") or player:FindFirstChild("Pets")
    if not inventory then return nil end

    local bestPet   = nil
    local bestStat  = -1

    for _, pet in ipairs(inventory:GetChildren()) do
        -- Coba baca stat pet (sesuaikan dengan property di game)
        local statValue = pet:GetAttribute("Power")
                       or pet:GetAttribute("Damage")
                       or pet:GetAttribute("Level")
                       or 0

        if statValue > bestStat then
            bestStat = statValue
            bestPet  = pet
        end
    end

    return bestPet
end

local function equipPetTick()
    if not Flags.AutoEquipBestPet then return end

    local bestPet = findBestPet()
    if not bestPet then return end

    pcall(function()
        Remotes.Fire("EquipPet", bestPet.Name)
    end)
end

function AutoEquipBestPet.Init()
    if _initialized then return end
    Scheduler.AddTask("AutoEquipBestPet_Tick", equipPetTick, 10.0)
    _initialized = true
    print("[AutoEquipBestPet] ✓ Diinisialisasi.")
end

function AutoEquipBestPet.Destroy()
    Scheduler.RemoveTask("AutoEquipBestPet_Tick")
    _initialized = false
end

return AutoEquipBestPet
