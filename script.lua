--[[
    Blox Fruits Multi-Script by Gta90988
    UI: Rayfield (как у популярных скриптов)
]]

-- ===== ОЧИСТКА =====
if getgenv().BF_HUB then
    pcall(function() getgenv().BF_HUB:Destroy() end)
end

-- ===== RAYFIELD UI =====
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Blox Fruits | Gta90988 Hub",
    LoadingTitle = "Загрузка...",
    LoadingSubtitle = "by Gta90988",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BF_Hub",
        FileName = "Config"
    },
    KeySystem = false
})
getgenv().BF_HUB = Window

-- ===== ПЕРЕМЕННЫЕ =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UserInput = game:GetService("UserInputService")
local p = Players.LocalPlayer

local State = {
    Fly = false,
    AutoFarm = false,
    BringMobs = false,
    AutoHaki = false,
    AutoClick = false,
    FastAttack = false,
    AutoFruit = false,
    AutoChest = false,
    ESP = false,
    WalkSpeed = 16,
    FarmDistance = 30
}

-- ===== ПОИСК МОБОВ =====
local function isMob(model)
    if not model or not model.Parent then return false end
    if model == p.Character then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

local function getNearestMob()
    local char = p.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, m in ipairs(workspace:GetChildren()) do
        if isMob(m) then
            local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < bestDist and d < 2000 then
                best, bestDist = m, d
            end
        end
    end
    return best
end

-- ===== FLY (по клавише F) =====
local flyBodyVel, flyBodyGyro
local flySpeed = 50

local function startFly()
    local char = p.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.Parent = hrp
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.P = 1000
    flyBodyGyro.Parent = hrp
end

local function stopFly()
    if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

UserInput.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and State.Fly then
        if flyBodyVel then
            stopFly()
        else
            startFly()
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if State.Fly and flyBodyVel and flyBodyGyro then
        local char = p.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local cam = workspace.CurrentCamera
        local move = Vector3.zero
        if UserInput:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
        flyBodyVel.Velocity = move * flySpeed
        flyBodyGyro.CFrame = cam.CFrame
    end
end)

-- ===== АТАКА =====
local function attack(mob)
    if not mob or not mob.Parent then return end
    local char = p.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- ===== MAIN TAB =====
local MainTab = Window:CreateTab("Главное", 4483362458)
local FarmSection = MainTab:CreateSection("Автофарм")

MainTab:CreateToggle({
    Name = "AutoFarm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v) State.AutoFarm = v end
})

MainTab:CreateToggle({
    Name = "Bring Mobs",
    CurrentValue = false,
    Flag = "BringMobs",
    Callback = function(v) State.BringMobs = v end
})

MainTab:CreateSlider({
    Name = "Дистанция фарма",
    Range = {5, 200},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "FarmDistance",
    Callback = function(v) State.FarmDistance = v end
})

-- ===== COMBAT TAB =====
local CombatTab = Window:CreateTab("Бой", 4483362458)

CombatTab:CreateToggle({
    Name = "Auto Haki (Buso + Ken)",
    CurrentValue = false,
    Flag = "AutoHaki",
    Callback = function(v) State.AutoHaki = v end
})

CombatTab:CreateToggle({
    Name = "Auto Click",
    CurrentValue = false,
    Flag = "AutoClick",
    Callback = function(v) State.AutoClick = v end
})

CombatTab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = false,
    Flag = "FastAttack",
    Callback = function(v) State.FastAttack = v end
})

-- ===== MOVEMENT TAB =====
local MoveTab = Window:CreateTab("Движение", 4483362458)

MoveTab:CreateToggle({
    Name = "Fly (клавиша F)",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v) State.Fly = v end
})

MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        State.WalkSpeed = v
        local char = p.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end
})

-- ===== MISC TAB =====
local MiscTab = Window:CreateTab("Разное", 4483362458)

MiscTab:CreateToggle({
    Name = "ESP мобов",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v) State.ESP = v end
})

MiscTab:CreateToggle({
    Name = "Auto Fruit",
    CurrentValue = false,
    Flag = "AutoFruit",
    Callback = function(v) State.AutoFruit = v end
})

MiscTab:CreateToggle({
    Name = "Auto Chest",
    CurrentValue = false,
    Flag = "AutoChest",
    Callback = function(v) State.AutoChest = v end
})

MiscTab:CreateButton({
    Name = "ТП к ближайшему мобу",
    Callback = function()
        local mob = getNearestMob()
        if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
        end
    end
})

MiscTab:CreateButton({
    Name = "Респавн",
    Callback = function()
        if p.Character then p.Character:BreakJoints() end
    end
})

-- ===== ЛОГИКА AUTO FARM =====
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoFarm then
            local mob = getNearestMob()
            if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if State.BringMobs then
                    mob.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                else
                    p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, State.FarmDistance)
                end
                attack(mob)
            end
        end
    end
end)

-- ===== AUTO HAKI =====
task.spawn(function()
    while task.wait(1) do
        if State.AutoHaki then
            local char = p.Character
            if char and not char:FindFirstChild("HasBuso") then
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
                end)
            end
        end
    end
end)

-- ===== AUTO CLICK =====
task.spawn(function()
    while task.wait(0.1) do
        if State.AutoClick then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- ===== FAST ATTACK =====
task.spawn(function()
    while task.wait() do
        if State.FastAttack and p.Character then
            local tool = p.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Cooldown") then
                tool.Cooldown.Value = 0
            end
        end
    end
end)

-- ===== ESP =====
task.spawn(function()
    local highlights = {}
    while task.wait(0.5) do
        if State.ESP then
            for _, m in ipairs(workspace:GetChildren()) do
                if isMob(m) and not highlights[m] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = m
                    highlights[m] = hl
                end
            end
        else
            for m, hl in pairs(highlights) do
                if hl then hl:Destroy() end
            end
            highlights = {}
        end
    end
end)

-- ===== AUTO FRUIT / CHEST =====
task.spawn(function()
    while task.wait(1) do
        if State.AutoFruit or State.AutoChest then
            for _, v in ipairs(workspace:GetChildren()) do
                if v:IsA("Tool") and v:FindFirstChild("Handle") then
                    if State.AutoFruit then
                        pcall(function()
                            v.Handle.CFrame = p.Character.HumanoidRootPart.CFrame
                        end)
                    end
                end
                if State.AutoChest and (v.Name:lower():find("chest") or v.Name == "Treasure") then
                    if v:FindFirstChild("Handle") then
                        pcall(function()
                            v.Handle.CFrame = p.Character.HumanoidRootPart.CFrame
                        end)
                    end
                end
            end
        end
    end
end)

-- ===== ANTI-AFK =====
p.Idled:Connect(function()
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end)

-- ===== УВЕДОМЛЕНИЕ =====
Rayfield:Notify({
    Title = "Gta90988 Hub",
    Content = "Скрипт загружен! Клавиша F — полет.",
    Duration = 5,
    Image = 4483362458
})
