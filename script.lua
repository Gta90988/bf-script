--[[
    Blox Fruits Bug Bounty Toolkit by Gta90988
    ЦЕЛЬ: найти баги для разработчика, НЕ для читерства
    Использовать ТОЛЬКО на альт-аккаунте
]]

if getgenv().BF_TOOLKIT then
    pcall(function() getgenv().BF_TOOLKIT:Destroy() end)
end

local Players   = game:GetService("Players")
local RunService= game:GetService("RunService")
local VIM       = game:GetService("VirtualInputManager")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Stats     = game:GetService("Stats")
local p = Players.LocalPlayer

-- ============================================================
-- UI
-- ============================================================
local sg = Instance.new("ScreenGui")
sg.Name = "BF_Toolkit"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = p:WaitForChild("PlayerGui")
getgenv().BF_TOOLKIT = sg

-- Главная панель
local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 480, 0, 380)
main.Position = UDim2.new(0.5, -240, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- Заголовок
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
title.Text = "  Blox Fruits Bug Bounty Toolkit"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.BorderSizePixel = 0
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Кнопка свернуть/закрыть
local closeBtn = Instance.new("TextButton", title)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- Вкладки (кнопки сверху)
local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -20, 0, 30)
tabBar.Position = UDim2.new(0, 10, 0, 45)
tabBar.BackgroundTransparency = 1

local tabNames = {"Farm", "Combat", "Visual", "Move", "TP", "Misc"}
local tabs = {}
local pages = {}
local activeTab

local function makePage(name)
    local page = Instance.new("ScrollingFrame", main)
    page.Size = UDim2.new(1, -20, 1, -90)
    page.Position = UDim2.new(0, 10, 0, 80)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    pages[name] = page
    return page
end

local function switchTab(name)
    if activeTab then activeTab.BackgroundColor3 = Color3.fromRGB(30, 30, 40) end
    activeTab = tabs[name]
    activeTab.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
    for n, pg in pairs(pages) do
        pg.Visible = (n == name)
    end
end

local tabX = 0
for _, name in ipairs(tabNames) do
    local b = Instance.new("TextButton", tabBar)
    b.Size = UDim2.new(0, 70, 0, 28)
    b.Position = UDim2.new(0, tabX, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(230, 230, 230)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    tabs[name] = b
    tabX = tabX + 75
    makePage(name)
end
switchTab("Farm")

-- Хелпер: кнопка
local function addButton(parent, text, callback, color)
    color = color or Color3.fromRGB(60, 130, 200)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 38)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    return btn
end

-- Хелпер: тумблер
local function addToggle(parent, text, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 32)
    frame.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 38)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14

    local state = false
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 60, 0, 22)
    btn.Position = UDim2.new(1, -70, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(200, 50, 50)
        pcall(callback, state)
    end)
    return frame
end

-- Хелпер: слайдер
local function addSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 56)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13

    local slider = Instance.new("Frame", frame)
    slider.Size = UDim2.new(1, -20, 0, 6)
    slider.Position = UDim2.new(0, 10, 0, 32)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.BorderSizePixel = 0
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    slider.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInput.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel)
            label.Text = text .. ": " .. val
            pcall(callback, val)
        end
    end)
end

-- ============================================================
-- ХЕЛПЕРЫ
-- ============================================================
local State = {
    AutoFarm = false, BringMobs = false, KillAura = false,
    AutoHaki = false, AutoClick = false, FastAttack = false,
    ESP_Mobs = false, ESP_Players = false, ESP_Fruits = false, ESP_Chests = false,
    Fly = false, InfiniteJump = false, NoClip = false,
    WalkSpeed = 16, JumpPower = 50, FarmDist = 3
}

local function isMob(m)
    if not m or m == p.Character then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    local hum = m:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and m:FindFirstChild("HumanoidRootPart")
end

local function getNearestMob(maxDist)
    maxDist = maxDist or 800
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, m in ipairs(workspace:GetChildren()) do
        if isMob(m) then
            local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < dist and d < maxDist then best, dist = m, d end
        end
    end
    return best, dist
end

local function attack()
    local char = p.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.03)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- ============================================================
-- FARM
-- ============================================================
local farmPage = pages.Farm

addToggle(farmPage, "AutoFarm (мобы)", function(v) State.AutoFarm = v end)
addToggle(farmPage, "Bring Mobs (притягивать)", function(v) State.BringMobs = v end)
addToggle(farmPage, "Kill Aura (бить всех рядом)", function(v) State.KillAura = v end)
addSlider(farmPage, "Дистанция фарма", 3, 50, 3, function(v) State.FarmDist = v end)
addButton(farmPage, "ТП к ближайшему мобу", function()
    local mob = getNearestMob()
    if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    end
end)
addButton(farmPage, "Авто-квест (получить у NPC)", function()
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest")
    end)
end, Color3.fromRGB(150, 100, 200))

task.spawn(function()
    while task.wait(0.15) do
        if State.AutoFarm then
            local mob = getNearestMob()
            if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if State.BringMobs then
                    pcall(function()
                        mob.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                    end)
                else
                    pcall(function()
                        p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, State.FarmDist)
                    end)
                end
                attack()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if State.KillAura and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            for _, m in ipairs(workspace:GetChildren()) do
                if isMob(m) then
                    local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < 30 then attack() break end
                end
            end
        end
    end
end)

-- ============================================================
-- COMBAT
-- ============================================================
local combatPage = pages.Combat

addToggle(combatPage, "Auto Haki (Buso + Ken)", function(v) State.AutoHaki = v end)
addToggle(combatPage, "Auto Click", function(v) State.AutoClick = v end)
addToggle(combatPage, "Fast Attack", function(v) State.FastAttack = v end)
addButton(combatPage, "Активировать Buso сейчас", function()
    pcall(function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso") end)
end)
addButton(combatPage, "Активировать Ken сейчас", function()
    pcall(function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Ken", true) end)
end)

task.spawn(function()
    while task.wait(1) do
        if State.AutoHaki and p.Character then
            if not p.Character:FindFirstChild("HasBuso") then
                pcall(function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso") end)
            end
            pcall(function() game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Ken", true) end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if State.AutoClick then attack() end
    end
end)

task.spawn(function()
    while task.wait() do
        if State.FastAttack and p.Character then
            local tool = p.Character:FindFirstChildOfClass("Tool")
            if tool then
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") and (v.Name:lower():find("cooldown") or v.Name:lower():find("cd")) then
                        pcall(function() v.Value = 0 end)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- VISUAL (ESP)
-- ============================================================
local visualPage = pages.Visual

local highlights = {}
local function clearHighlight(obj)
    if highlights[obj] then
        pcall(function() highlights[obj]:Destroy() end)
        highlights[obj] = nil
    end
end

local function addHighlight(obj, color)
    if highlights[obj] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0
    hl.Parent = obj
    highlights[obj] = hl
end

addToggle(visualPage, "ESP Мобы", function(v)
    State.ESP_Mobs = v
    if not v then for o in pairs(highlights) do clearHighlight(o) end end
end)
addToggle(visualPage, "ESP Игроки", function(v)
    State.ESP_Players = v
    if not v then for o in pairs(highlights) do clearHighlight(o) end end
end)
addToggle(visualPage, "ESP Фрукты (Tools)", function(v)
    State.ESP_Fruits = v
    if not v then for o in pairs(highlights) do clearHighlight(o) end end
end)
addToggle(visualPage, "ESP Сундуки", function(v)
    State.ESP_Chests = v
    if not v then for o in pairs(highlights) do clearHighlight(o) end end
end)

task.spawn(function()
    while task.wait(0.5) do
        if State.ESP_Mobs then
            for _, m in ipairs(workspace:GetChildren()) do
                if isMob(m) then addHighlight(m, Color3.fromRGB(255, 60, 60)) end
            end
        end
        if State.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= p and plr.Character then
                    addHighlight(plr.Character, Color3.fromRGB(60, 200, 60))
                end
            end
        end
        if State.ESP_Fruits then
            for _, v in ipairs(workspace:GetChildren()) do
                if v:IsA("Tool") then addHighlight(v, Color3.fromRGB(255, 180, 50)) end
            end
        end
        if State.ESP_Chests then
            for _, v in ipairs(workspace:GetChildren()) do
                local n = v.Name:lower()
                if n:find("chest") or n:find("treasure") then
                    addHighlight(v, Color3.fromRGB(255, 230, 80))
                end
            end
        end
    end
end)

-- ============================================================
-- MOVEMENT
-- ============================================================
local movePage = pages.Move
local flyVel, flyGyro
local FLY_SPEED = 60

addToggle(movePage, "Fly (F — вкл/выкл)", function(v) State.Fly = v end)
addToggle(movePage, "Infinite Jump", function(v) State.InfiniteJump = v end)
addToggle(movePage, "NoClip", function(v) State.NoClip = v end)
addSlider(movePage, "WalkSpeed", 16, 300, 16, function(v)
    State.WalkSpeed = v
    if p.Character then
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end)
addSlider(movePage, "JumpPower", 50, 500, 50, function(v)
    State.JumpPower = v
    if p.Character then
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.UseJumpPower = true
            h.JumpPower = v
        end
    end
end)

UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F and State.Fly then
        local char = p.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if flyVel then
            flyVel:Destroy(); flyGyro:Destroy()
            flyVel, flyGyro = nil, nil
        else
            flyVel = Instance.new("BodyVelocity")
            flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyVel.Velocity = Vector3.zero
            flyVel.Parent = hrp
            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyGyro.P = 1000
            flyGyro.Parent = hrp
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if State.Fly and flyVel and flyGyro and p.Character then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cam = workspace.CurrentCamera
            local move = Vector3.zero
            if UserInput:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            flyVel.Velocity = move * FLY_SPEED
            flyGyro.CFrame = cam.CFrame
        end
    end
end)

UserInput.JumpRequest:Connect(function()
    if State.InfiniteJump and p.Character then
        local h = p.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if State.NoClip and p.Character then
        for _, v in ipairs(p.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end)

-- Авто-применение WalkSpeed при респавне
p.CharacterAdded:Connect(function(char)
    task.wait(1)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = State.WalkSpeed
        h.UseJumpPower = true
        h.JumpPower = State.JumpPower
    end
end)

-- ============================================================
-- TELEPORT
-- ============================================================
local tpPage = pages.TP

local islands = {
    -- Первое море
    ["Starter Island"] = CFrame.new(0, 10, 0),
    ["Marine Ford"] = CFrame.new(-2000, 20, -2000),
    ["Bandit Island"] = CFrame.new(-1500, 10, 100),
    -- Добавь свои координаты по мере необходимости
}

addButton(tpPage, "ТП к ближайшему мобу", function()
    local mob = getNearestMob()
    if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    end
end)

addButton(tpPage, "ТП к случайному игроку", function()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= p and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, plr)
        end
    end
    if #list > 0 then
        local target = list[math.random(#list)]
        p.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
    end
end)

for name, cf in pairs(islands) do
    addButton(tpPage, "ТП: " .. name, function()
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.CFrame = cf
        end
    end, Color3.fromRGB(100, 100, 180))
end

-- ============================================================
-- MISC
-- ============================================================
local miscPage = pages.Misc

addToggle(miscPage, "Anti-AFK", function(v) getgenv().AntiAFK = v end)

addButton(miscPage, "Серверный хоп", function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, srv in ipairs(servers.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id, p)
            break
        end
    end
end, Color3.fromRGB(180, 100, 100))

addButton(miscPage, "Респавн", function()
    if p.Character then p.Character:BreakJoints() end
end, Color3.fromRGB(180, 100, 100))

addButton(miscPage, "Показать FPS / Ping", function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    game.StarterGui:SetCore("SendNotification", {
        Title = "Info",
        Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms",
        Duration = 5
    })
end)

addButton(miscPage, "Скопировать позицию (для баг-репорта)", function()
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local pos = p.Character.HumanoidRootPart.Position
        local str = string.format("Pos: %.0f, %.0f, %.0f | Place: %d | JobId: %s",
            pos.X, pos.Y, pos.Z, game.PlaceId, game.JobId)
        if setclipboard then setclipboard(str) end
        game.StarterGui:SetCore("SendNotification", {
            Title = "Скопировано",
            Text = str,
            Duration = 5
        })
    end
end, Color3.fromRGB(80, 160, 80))

-- Anti-AFK
p.Idled:Connect(function()
    if getgenv().AntiAFK ~= false then
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end)

-- ============================================================
-- ГОТОВО
-- ============================================================
game.StarterGui:SetCore("SendNotification", {
    Title = "Bug Bounty Toolkit",
    Text = "Загружено. Удачи в поиске багов!",
    Duration = 5
})
warn("[BF Toolkit] Загружено успешно")
