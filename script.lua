--[[
    Blox Fruits Auto Farm Script
    Инжектор: Xeno (совместим с большинством)
    Использование: только в образовательных целях
]]

-- ===== ЗАЩИТА ОТ ПОВТОРНОГО ЗАПУСКА =====
if getgenv().BF_LOADED then
    getgenv().BF_LOADED:Destroy()
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/InfernusScripts/Null-Fire/main/Library.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== КОНФИГ =====
local Config = {
    AutoFarm = false,
    AutoFarmLevel = false,
    BringMobs = false,
    AutoHaki = false,
    AutoBusoshoku = false,
    AutoKenbun = false,
    AutoClick = false,
    AutoSword = false,
    AutoFruit = false,
    AutoChest = false,
    FastAttack = true,
    AttackRange = 30,
    FarmDistance = 30,
    SelectedFruit = "None",
}

-- ===== СОЗДАНИЕ UI =====
local Window = Library:CreateWindow({
    Title = "Blox Fruits | Xeno",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("Главное"),
    Combat = Window:AddTab("Бой"),
    Fruit = Window:AddTab("Фрукты"),
    Misc = Window:AddTab("Разное"),
}

-- ===== ГЛАВНАЯ ВКЛАДКА =====
local MainGroup = Tabs.Main:AddLeftGroupbox("Автофарм")

MainGroup:AddToggle("AutoFarm", {
    Text = "Автофарм мобов",
    Default = false,
    Callback = function(state)
        Config.AutoFarm = state
    end
})

MainGroup:AddToggle("AutoFarmLevel", {
    Text = "Автофарм уровня (по квестам)",
    Default = false,
    Callback = function(state)
        Config.AutoFarmLevel = state
    end
})

MainGroup:AddToggle("BringMobs", {
    Text = "Притягивать мобов",
    Default = false,
    Callback = function(state)
        Config.BringMobs = state
    end
})

MainGroup:AddSlider("FarmDistance", {
    Text = "Дистанция фарма",
    Default = 30,
    Min = 5,
    Max = 200,
    Rounding = 1,
    Callback = function(value)
        Config.FarmDistance = value
    end
})

-- ===== ВКЛАДКА БОЯ =====
local CombatGroup = Tabs.Combat:AddLeftGroupbox("Боевые функции")

CombatGroup:AddToggle("AutoHaki", {
    Text = "Авто Хаки (все виды)",
    Default = false,
    Callback = function(state)
        Config.AutoHaki = state
    end
})

CombatGroup:AddToggle("AutoBusoshoku", {
    Text = "Авто Busoshoku Haki",
    Default = false,
    Callback = function(state)
        Config.AutoBusoshoku = state
    end
})

CombatGroup:AddToggle("AutoKenbun", {
    Text = "Авто Kenbunshoku Haki",
    Default = false,
    Callback = function(state)
        Config.AutoKenbun = state
    end
})

CombatGroup:AddToggle("FastAttack", {
    Text = "Быстрая атака (no cooldown)",
    Default = true,
    Callback = function(state)
        Config.FastAttack = state
    end
})

CombatGroup:AddToggle("AutoClick", {
    Text = "Авто-клик",
    Default = false,
    Callback = function(state)
        Config.AutoClick = state
    end
})

CombatGroup:AddSlider("AttackRange", {
    Text = "Дистанция атаки",
    Default = 30,
    Min = 5,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        Config.AttackRange = value
    end
})

-- ===== ВКЛАДКА ФРУКТОВ =====
local FruitGroup = Tabs.Fruit:AddLeftGroupbox("Автофрукт")

FruitGroup:AddToggle("AutoFruit", {
    Text = "Авто-сбор фруктов",
    Default = false,
    Callback = function(state)
        Config.AutoFruit = state
    end
})

FruitGroup:AddToggle("AutoChest", {
    Text = "Авто-сбор сундуков",
    Default = false,
    Callback = function(state)
        Config.AutoChest = state
    end
})

-- ===== ВКЛАДКА РАЗНОЕ =====
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Разное")

MiscGroup:AddButton({
    Text = "Телепорт к ближайшему мобу",
    Func = function()
        local nearest = getNearestMob()
        if nearest then
            LocalPlayer.Character.HumanoidRootPart.CFrame = nearest.CFrame * CFrame.new(0, 0, Config.FarmDistance)
        end
    end
})

MiscGroup:AddButton({
    Text = "Респавн персонажа",
    Func = function()
        LocalPlayer.Character:BreakJoints()
    end
})

-- ===== ФУНКЦИИ =====

function getNearestMob()
    local nearest, dist = nil, math.huge
    for _, mob in pairs(workspace.Enemies:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") 
           and mob.Humanoid.Health > 0 then
            local d = (mob.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist and d < 500 then
                nearest, dist = mob.HumanoidRootPart, d
            end
        end
    end
    return nearest
end

function attackMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return end
    
    -- Активация Busoshoku Haki
    if Config.AutoBusoshoku then
        local hasHaki = LocalPlayer.Character:FindFirstChild("HasBuso")
        if not hasHaki then
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
        end
    end
    
    -- Активация Kenbunshoku
    if Config.AutoKenbun then
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Ken", true)
    end
    
    -- Атака
    if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
    end
end

-- ===== АВТОФАРМ =====
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoFarm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local nearest = getNearestMob()
            if nearest and nearest.Parent:FindFirstChild("Humanoid") and nearest.Parent.Humanoid.Health > 0 then
                if Config.BringMobs then
                    nearest.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                else
                    LocalPlayer.Character.HumanoidRootPart.CFrame = nearest.CFrame * CFrame.new(0, 0, Config.FarmDistance)
                end
                attackMob(nearest.Parent)
            end
        end
    end
end)

-- ===== АВТОФАРМ УРОВНЯ (упрощённый) =====
task.spawn(function()
    while task.wait(1) do
        if Config.AutoFarmLevel then
            local quest = game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("GetCurrentQuest")
            if quest then
                -- логика выполнения квеста
                getgenv().CurrentQuest = quest
            end
        end
    end
end)

-- ===== АВТО ХАКИ =====
task.spawn(function()
    while task.wait(1) do
        if Config.AutoHaki then
            if not LocalPlayer.Character:FindFirstChild("HasBuso") then
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
            end
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Ken", true)
        end
    end
end)

-- ===== АВТО-КЛИК =====
task.spawn(function()
    while task.wait(0.1) do
        if Config.AutoClick then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end
end)

-- ===== АВТО-ФРУКТЫ =====
task.spawn(function()
    while task.wait(1) do
        if Config.AutoFruit then
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and v:FindFirstChild("Handle") then
                    v.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

-- ===== АВТО-СУНДУКИ =====
task.spawn(function()
    while task.wait(1) do
        if Config.AutoChest then
            for _, v in pairs(workspace:GetChildren()) do
                if v.Name == "Chest" or v.Name == "Treasure" then
                    if v:FindFirstChild("Handle") then
                        v.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end
end)

-- ===== БЫСТРАЯ АТАКА (обход кулдауна) =====
task.spawn(function()
    while task.wait() do
        if Config.FastAttack then
            if LocalPlayer.Character then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Cooldown") then
                    tool.Cooldown.Value = 0
                end
            end
        end
    end
end)

-- ===== АНТИ-AFK =====
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

getgenv().BF_LOADED = Window
Library:Notify("Blox Fruits Script загружен!", 5)