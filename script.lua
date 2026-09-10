--[[
    Blox Fruits Advanced Toolkit v7 by Gta90988
    Фиксы: ESP remove | Chest TP через Tween | Player Info ESP | Auto Quest
]]

if getgenv().BF_TOOLKIT then pcall(function() getgenv().BF_TOOLKIT:Destroy() end) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local p = Players.LocalPlayer

-- ===== КОНФИГ =====
local Config = {
    FlyTime = 1.5,             -- медленнее для античита
    AttackRadius = 40,
    FarmDelay = 0.5,
    AutoDetect = true,
    WalkSpeed = 16,
    CurrentSea = "Auto",
}

local function randFloat(a, b) return a + math.random() * (b - a) end
local function safePosition(cf, dist)
    local angle = math.rad(math.random(0, 360))
    return cf * CFrame.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

-- Плавный полёт (защита от anti-cheat)
local function flyTo(hrp, targetCFrame, duration)
    duration = duration or Config.FlyTime
    if Config.AutoDetect then duration = duration * randFloat(0.9, 1.3) end
    local tween = TweenService:Create(hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

-- ===== РЕКУРСИВНЫЙ ПОИСК (ФИКС СУНДУКОВ) =====
local function recursiveFind(predicate, maxDepth)
    maxDepth = maxDepth or 6
    local found = {}
    local function scan(parent, depth)
        if depth > maxDepth then return end
        for _, obj in ipairs(parent:GetChildren()) do
            if predicate(obj) then table.insert(found, obj) end
            if obj:IsA("Folder") or obj:IsA("Model") then
                scan(obj, depth + 1)
            end
        end
    end
    scan(workspace, 0)
    return found
end

-- ===== МОБЫ (ВСЯ КАРТА) =====
local function isMob(m)
    if not m or m == p.Character then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    local hum = m:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and m:FindFirstChild("HumanoidRootPart")
end

-- ФИКС: без ограничения дистанции — вся карта
local function getAllMobs() return recursiveFind(isMob, 3) end

-- ===== СУНДУКИ (ФИКС) =====
local function isChest(obj)
    local n = obj.Name:lower()
    return (n:find("chest") or n:find("treasure") or n:find("crate"))
        and (obj:IsA("Model") or obj:IsA("BasePart"))
        and (obj:FindFirstChild("Handle") or obj.PrimaryPart)
end
local function getAllChests() return recursiveFind(isChest, 5) end

-- ===== ФРУКТЫ =====
local FRUITS = {["Rocket"]=true,["Spin"]=true,["Chop"]=true,["Spring"]=true,["Bomb"]=true,["Smoke"]=true,["Spike"]=true,["Flame"]=true,["Falcon"]=true,["Ice"]=true,["Sand"]=true,["Dark"]=true,["Diamond"]=true,["Light"]=true,["Rubber"]=true,["Barrier"]=true,["Magma"]=true,["Door"]=true,["Quake"]=true,["Buddha"]=true,["Love"]=true,["Spider"]=true,["Sound"]=true,["Phoenix"]=true,["Portal"]=true,["Rumble"]=true,["Pain"]=true,["Blizzard"]=true,["Gravity"]=true,["Mammoth"]=true,["T-Rex"]=true,["Dough"]=true,["Shadow"]=true,["Venom"]=true,["Control"]=true,["Spirit"]=true,["Dragon"]=true,["Leopard"]=true,["Kitsune"]=true}
local function isFruit(obj) return obj:IsA("Tool") and obj:FindFirstChild("Handle") and FRUITS[obj.Name] end

-- ===== ЯГОДЫ =====
local BERRY_TYPES = {["Green Toad Berry"]=true,["White Cloud Berry"]=true,["Blue Icicle Berry"]=true,["Purple Jelly Berry"]=true,["Pink Pig Berry"]=true,["Orange Berry"]=true,["Yellow Star Berry"]=true,["Red Cherry Berry"]=true}
local function isBerry(obj) return BERRY_TYPES[obj.Name] ~= nil end

-- ===== ОПРЕДЕЛЕНИЕ МОРЯ =====
local function getCurrentSea()
    if Config.CurrentSea ~= "Auto" then return Config.CurrentSea end
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 1 end
    local pos = char.HumanoidRootPart.Position
    if pos.Z > 4000 or pos.X > 4000 then return 3
    elseif pos.Z > -1000 and pos.Z < 3000 and pos.X > -1000 and pos.X < 1500 then return 2
    else return 1 end
end

-- ===== ИНФО ИГРОКА (ФИКС: HP, LVL, FRUIT) =====
local function getPlayerInfo(plr)
    local hp, maxHp = 0, 100
    local lvl, fruit = "?", "None"
    if plr.Character then
        local h = plr.Character:FindFirstChildOfClass("Humanoid")
        if h then hp, maxHp = math.floor(h.Health), math.floor(h.MaxHealth) end
    end
    pcall(function() lvl = plr.Data.Level.Value end)
    pcall(function() fruit = plr.Data.Fruit.Value end)
    return hp, maxHp, lvl, fruit
end

-- ===== UI =====
local sg = Instance.new("ScreenGui")
sg.Name = "BF_Toolkit_v7"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = p:WaitForChild("PlayerGui")
getgenv().BF_TOOLKIT = sg

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 560, 0, 460)
main.Position = UDim2.new(0.5, -280, 0.5, -230)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, -80, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BF Toolkit v7 | ESP Fix + Player Info"
titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -20, 0, 30)
tabBar.Position = UDim2.new(0, 10, 0, 46)
tabBar.BackgroundTransparency = 1

local tabNames = {"Farm", "Sea", "Visual", "Teleport", "Move", "Misc"}
local tabs, pages, activeTab = {}, {}, nil

local function makePage()
    local pg = Instance.new("ScrollingFrame", main)
    pg.Size = UDim2.new(1, -20, 1, -90)
    pg.Position = UDim2.new(0, 10, 0, 84)
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.ScrollBarThickness = 4
    pg.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pg.CanvasSize = UDim2.new(0, 0, 0, 0)
    pg.Visible = false
    return pg
end

local function switchTab(name)
    if activeTab then activeTab.BackgroundColor3 = Color3.fromRGB(30, 30, 42) end
    activeTab = tabs[name]
    activeTab.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
end

local tx = 0
for _, name in ipairs(tabNames) do
    local b = Instance.new("TextButton", tabBar)
    b.Size = UDim2.new(0, 78, 0, 28)
    b.Position = UDim2.new(0, tx, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(230, 230, 230)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    tabs[name] = b
    tx = tx + 82
    pages[name] = makePage()
end
switchTab("Farm")

-- UI Helpers
local function addButton(parent, text, cb, color)
    color = color or Color3.fromRGB(60, 130, 200)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 38)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
    return btn
end

local function addToggle(parent, text, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 32)
    f.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 38)
    f.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -80, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(230, 230, 230)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    local state = false
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 60, 0, 22)
    b.Position = UDim2.new(1, -70, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    b.Text = "OFF"
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function()
        state = not state
        b.Text = state and "ON" or "OFF"
        b.BackgroundColor3 = state and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(200, 50, 50)
        pcall(cb, state)
    end)
    return f
end

local function addSlider(parent, text, min, max, default, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 50)
    f.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 56)
    f.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    local slider = Instance.new("Frame", f)
    slider.Size = UDim2.new(1, -24, 0, 6)
    slider.Position = UDim2.new(0, 12, 0, 32)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
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
            lbl.Text = text .. ": " .. val
            pcall(cb, val)
        end
    end)
end

-- ===== STATE =====
local State = {
    AutoFarm = false, BringMobs = false, AutoHaki = false,
    AutoClick = false, ESP_Mobs = false, ESP_Players = false,
    ESP_Fruits = false, ESP_Berries = false, ESP_Chests = false,
    Fly = false, AutoQuestFull = false, AutoChest = false
}

-- ===== ESP (ФИКС ВЫКЛЮЧЕНИЯ) =====
local espObjects = {}

-- ФИКС: удаляем Highlight через :Destroy(), а не Enabled=false
local function destroyESP(obj)
    if espObjects[obj] then
        for _, v in pairs(espObjects[obj]) do
            if v and typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
        end
        espObjects[obj] = nil
    end
end

local function clearAllESP()
    for obj, _ in pairs(espObjects) do
        destroyESP(obj)
    end
end

local function createESP(obj, color, extraLine)
    if espObjects[obj] then return end
    local data = {}
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.45
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    data.hl = hl

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 240, 0, extraLine and 50 or 30)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = obj.Name
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    data.bb = bb
    data.lbl = lbl
    data.baseName = obj.Name

    if extraLine then
        local sub = Instance.new("TextLabel", bb)
        sub.Size = UDim2.new(1, 0, 0, 16)
        sub.Position = UDim2.new(0, 0, 0, 20)
        sub.BackgroundTransparency = 1
        sub.Text = extraLine
        sub.TextColor3 = Color3.fromRGB(255, 255, 255)
        sub.TextStrokeTransparency = 0
        sub.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        data.subLbl = sub
    end

    espObjects[obj] = data
end

local function updateESPLabels()
    local myChar = p.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myPos = myChar.HumanoidRootPart.Position
    for obj, data in pairs(espObjects) do
        if not obj.Parent then destroyESP(obj) continue end
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle") or obj.PrimaryPart
        if root then
            local d = math.floor((root.Position - myPos).Magnitude)
            data.lbl.Text = data.baseName .. " [" .. d .. "m]"
        end
    end
end

-- ===== FARM TAB =====
local farmPage = pages.Farm
addToggle(farmPage, "AutoFarm (медленный полёт)", function(v) State.AutoFarm = v end)
addToggle(farmPage, "Bring Mobs", function(v) State.BringMobs = v end)
addToggle(farmPage, "Auto Haki (Buso + Ken)", function(v) State.AutoHaki = v end)
addToggle(farmPage, "Auto Click", function(v) State.AutoClick = v end)
addToggle(farmPage, "Auto Chest (ФИКС v7)", function(v) State.AutoChest = v end)
addSlider(farmPage, "Зона атаки", 5, 200, 40, function(v) Config.AttackRadius = v end)
addSlider(farmPage, "Задержка атаки (x0.1с)", 1, 20, 5, function(v) Config.FarmDelay = v * 0.1 end)
addSlider(farmPage, "Время полёта (x0.1с)", 5, 30, 15, function(v) Config.FlyTime = v * 0.1 end)

addButton(farmPage, "ТП к ближайшему мобу", function()
    local mobs = getAllMobs()
    if #mobs == 0 then return end
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, m in ipairs(mobs) do
        local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
        if d < dist then best, dist = m, d end
    end
    if best then flyTo(hrp, safePosition(best.HumanoidRootPart.CFrame, 3)) end
end)

addButton(farmPage, "ТП к ближайшему сундуку (v7 FIX)", function()
    local chests = getAllChests()
    if #chests == 0 then
        game.StarterGui:SetCore("SendNotification", {Title="Сундуки", Text="Не найдено", Duration=3})
        return
    end
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, c in ipairs(chests) do
        local h = c:FindFirstChild("Handle") or c.PrimaryPart
        if h then
            local d = (h.Position - hrp.Position).Magnitude
            if d < dist then best, dist = c, d end
        end
    end
    if best then
        local h = best:FindFirstChild("Handle") or best.PrimaryPart
        flyTo(hrp, h.CFrame * CFrame.new(0, 0, 3))
        game.StarterGui:SetCore("SendNotification", {Title="Сундук", Text=best.Name .. " [" .. math.floor(dist) .. "m]", Duration=2})
    end
end)

addButton(farmPage, "DEBUG: сколько сундуков найдено", function()
    local chests = getAllChests()
    game.StarterGui:SetCore("SendNotification", {
        Title = "DEBUG Chests",
        Text = "Всего найдено: " .. #chests,
        Duration = 5
    })
end, Color3.fromRGB(180, 150, 50))

-- ===== SEA TAB =====
local seaPage = pages.Sea

local QuestNPCs = {
    [1] = {
        {name="Bandit", cframe=CFrame.new(-1500,10,100), quest="BanditQuest1", num=1, lvl=1},
        {name="Monkey", cframe=CFrame.new(-1500,20,200), quest="JungleQuest", num=1, lvl=10},
        {name="Pirate", cframe=CFrame.new(-1200,20,3300), quest="PirateQuest", num=1, lvl=30},
        {name="Brute", cframe=CFrame.new(-1300,20,4300), quest="DesertQuest", num=1, lvl=60},
        {name="Snow Bandit", cframe=CFrame.new(-1100,20,5800), quest="SnowQuest", num=1, lvl=90},
    },
    [2] = {
        {name="Swan Pirate", cframe=CFrame.new(-400,30,2000), quest="SwanQuest", num=1, lvl=700},
        {name="Zombie", cframe=CFrame.new(-4000,30,-5000), quest="ZombieQuest", num=1, lvl=1000},
        {name="Ice Pirate", cframe=CFrame.new(500,30,-1500), quest="IceQuest", num=1, lvl=1200},
    },
    [3] = {
        {name="Port Pirate", cframe=CFrame.new(-300,20,5000), quest="PortQuest", num=1, lvl=1500},
        {name="Hydra Crew", cframe=CFrame.new(5000,30,1000), quest="HydraQuest", num=1, lvl=1575},
        {name="Tree NPC", cframe=CFrame.new(2000,50,-2000), quest="TreeQuest", num=1, lvl=1700},
    }
}

local seaIndicator = Instance.new("TextLabel", seaPage)
seaIndicator.Size = UDim2.new(1, -10, 0, 30)
seaIndicator.Position = UDim2.new(0, 5, 0, 5)
seaIndicator.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
seaIndicator.TextColor3 = Color3.fromRGB(100, 200, 255)
seaIndicator.Font = Enum.Font.GothamBold
seaIndicator.TextSize = 14
seaIndicator.BorderSizePixel = 0
seaIndicator.Text = "Море: определение..."
Instance.new("UICorner", seaIndicator).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    while task.wait(2) do
        local sea = getCurrentSea()
        local lvl = "?"
        pcall(function() lvl = p.Data.Level.Value end)
        seaIndicator.Text = "Море: " .. sea .. " | Уровень: " .. lvl
    end
end)

addButton(seaPage, "Установить: Авто", function() Config.CurrentSea = "Auto" end, Color3.fromRGB(100, 180, 100))
addButton(seaPage, "Установить: 1 море", function() Config.CurrentSea = 1 end, Color3.fromRGB(100, 130, 200))
addButton(seaPage, "Установить: 2 море", function() Config.CurrentSea = 2 end, Color3.fromRGB(100, 130, 200))
addButton(seaPage, "Установить: 3 море", function() Config.CurrentSea = 3 end, Color3.fromRGB(100, 130, 200))

addToggle(seaPage, "Auto Quest (полный цикл)", function(v) State.AutoQuestFull = v end)

addButton(seaPage, "Взять квест по уровню", function()
    local sea = getCurrentSea()
    local lvl = 1
    pcall(function() lvl = p.Data.Level.Value end)
    local quests = QuestNPCs[sea] or {}
    local best = nil
    for _, q in ipairs(quests) do
        if lvl >= q.lvl then best = q end
    end
    if best and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        flyTo(p.Character.HumanoidRootPart, best.cframe * CFrame.new(0, 0, 5), 1.5)
        task.wait(0.5)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", best.quest, best.num)
        end)
    end
end, Color3.fromRGB(150, 100, 200))

addButton(seaPage, "Сдать квест", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("CompleteQuest") end)
end, Color3.fromRGB(100, 180, 100))

-- ===== VISUAL TAB (ФИКС) =====
local visualPage = pages.Visual

addToggle(visualPage, "ESP Мобы (вся карта)", function(v)
    State.ESP_Mobs = v
    if not v then
        for obj, _ in pairs(espObjects) do
            if isMob(obj) then destroyESP(obj) end
        end
    end
end)

addToggle(visualPage, "ESP Игроки (HP + LVL + FRUIT)", function(v)
    State.ESP_Players = v
    if not v then
        for obj, _ in pairs(espObjects) do
            if Players:GetPlayerFromCharacter(obj) then destroyESP(obj) end
        end
    end
end)

addToggle(visualPage, "ESP Фрукты", function(v)
    State.ESP_Fruits = v
    if not v then
        for obj, _ in pairs(espObjects) do
            if isFruit(obj) then destroyESP(obj) end
        end
    end
end)

addToggle(visualPage, "ESP Ягоды для ауры", function(v)
    State.ESP_Berries = v
    if not v then
        for obj, _ in pairs(espObjects) do
            if isBerry(obj) then destroyESP(obj) end
        end
    end
end)

addToggle(visualPage, "ESP Сундуки", function(v)
    State.ESP_Chests = v
    if not v then
        for obj, _ in pairs(espObjects) do
            if isChest(obj) then destroyESP(obj) end
        end
    end
end)

addButton(visualPage, "ВЫКЛЮЧИТЬ ВСЁ ESP (FIX)", function()
    clearAllESP()
    State.ESP_Mobs = false
    State.ESP_Players = false
    State.ESP_Fruits = false
    State.ESP_Berries = false
    State.ESP_Chests = false
    game.StarterGui:SetCore("SendNotification", {Title="ESP", Text="Всё выключено", Duration=3})
end, Color3.fromRGB(180, 100, 100))

-- ===== TELEPORT TAB =====
local tpPage = pages.Teleport
local ISLANDS = {
    [1] = {
        ["Starter Island"]=CFrame.new(0,20,0),["Marine Fortress"]=CFrame.new(-2500,30,-2500),
        ["Middle Town"]=CFrame.new(-600,15,600),["Jungle"]=CFrame.new(-1500,20,200),
        ["Pirate Village"]=CFrame.new(-1200,20,3300),["Desert"]=CFrame.new(-1300,20,4300),
        ["Frozen Village"]=CFrame.new(-1100,20,5800),["Colosseum"]=CFrame.new(-1500,40,2000),
        ["Magma Village"]=CFrame.new(-5200,30,1000),["Underwater City"]=CFrame.new(-4000,-200,5000),
        ["Fountain City"]=CFrame.new(5200,30,4000),["Skylands"]=CFrame.new(-4500,800,-3000),
    },
    [2] = {
        ["Cafe"]=CFrame.new(-380,15,260),["Kingdom of Rose"]=CFrame.new(-400,30,2000),
        ["Green Zone"]=CFrame.new(100,20,500),["Graveyard Island"]=CFrame.new(-4000,30,-5000),
        ["Ice Castle"]=CFrame.new(500,30,-1500),["Snow Mountain"]=CFrame.new(1000,50,-1000),
        ["Forgotten Island"]=CFrame.new(-3000,20,-2000),["Hot and Cold"]=CFrame.new(-5000,30,-3000),
    },
    [3] = {
        ["Port Town"]=CFrame.new(-300,20,5000),["Hydra Island"]=CFrame.new(5000,30,1000),
        ["Great Tree"]=CFrame.new(2000,50,-2000),["Floating Turtle"]=CFrame.new(3000,30,3000),
        ["Tiki Outpost"]=CFrame.new(-1000,20,-5000),["Candy Cane Land"]=CFrame.new(2000,30,3000),
        ["Prehistoric Island"]=CFrame.new(5000,30,-4000),
    }
}

addSlider(tpPage, "Скорость ТП (x0.1с)", 5, 50, 15, function(v) Config.FlyTime = v * 0.1 end)

addButton(tpPage, "ТП к ближайшему сундуку", function()
    local chests = getAllChests()
    if #chests == 0 then return end
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, c in ipairs(chests) do
        local h = c:FindFirstChild("Handle") or c.PrimaryPart
        if h then
            local d = (h.Position - hrp.Position).Magnitude
            if d < dist then best, dist = c, d end
        end
    end
    if best then
        local h = best:FindFirstChild("Handle") or best.PrimaryPart
        flyTo(hrp, h.CFrame * CFrame.new(0, 0, 3))
    end
end)

for sea, islands in pairs(ISLANDS) do
    for name, cf in pairs(islands) do
        addButton(tpPage, "[" .. sea .. "] " .. name, function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                flyTo(p.Character.HumanoidRootPart, cf)
            end
        end, Color3.fromRGB(80 + sea * 40, 100, 180))
    end
end

-- ===== MOVE TAB =====
local movePage = pages.Move
local flyVel, flyGyro

addToggle(movePage, "Fly (клавиша F)", function(v) State.Fly = v end)
addSlider(movePage, "WalkSpeed", 16, 200, 16, function(v)
    Config.WalkSpeed = v
    local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end)

UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F and State.Fly then
        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if flyVel then
            flyVel:Destroy(); flyGyro:Destroy(); flyVel, flyGyro = nil, nil
        else
            flyVel = Instance.new("BodyVelocity")
            flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
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
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
            flyVel.Velocity = move * 50
            flyGyro.CFrame = cam.CFrame
        end
    end
end)

-- ===== MISC TAB =====
local miscPage = pages.Misc
addToggle(miscPage, "Anti-AFK", function(v) getgenv().AntiAFK = v end)
addButton(miscPage, "Респавн", function()
    if p.Character then p.Character:BreakJoints() end
end, Color3.fromRGB(180, 100, 100))

-- ===== АВТОФАРМ =====
task.spawn(function()
    while task.wait(Config.FarmDelay) do
        if State.AutoFarm then
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1) continue end
            local hrp = char.HumanoidRootPart
            local mobs = getAllMobs()
            if #mobs > 0 then
                local best, dist = nil, math.huge
                for _, m in ipairs(mobs) do
                    local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then best, dist = m, d end
                end
                if best then
                    flyTo(hrp, safePosition(best.HumanoidRootPart.CFrame, 3))
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(Config.FarmDelay * 0.3)
                    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end
        end
    end
end)

-- ===== AUTO CHEST (v7 FIX) =====
task.spawn(function()
    while task.wait(3) do
        if State.AutoChest then
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local hrp = char.HumanoidRootPart
            local chests = getAllChests()
            local best, dist = nil, math.huge
            for _, c in ipairs(chests) do
                local h = c:FindFirstChild("Handle") or c.PrimaryPart
                if h then
                    local d = (h.Position - hrp.Position).Magnitude
                    if d < dist and d < 600 then best, dist = c, d end
                end
            end
            if best then
                local h = best:FindFirstChild("Handle") or best.PrimaryPart
                flyTo(hrp, h.CFrame * CFrame.new(0, 0, 3))
                task.wait(0.5)
            end
        end
    end
end)

-- ===== AUTO QUEST FULL =====
task.spawn(function()
    while task.wait(3) do
        if State.AutoQuestFull then
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local sea = getCurrentSea()
            local lvl = 1
            pcall(function() lvl = p.Data.Level.Value end)
            local quests = QuestNPCs[sea] or {}
            local best = nil
            for _, q in ipairs(quests) do
                if lvl >= q.lvl then best = q end
            end
            if best then
                flyTo(char.HumanoidRootPart, best.cframe * CFrame.new(0, 0, 5), 1.5)
                task.wait(0.5)
                pcall(function()
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", best.quest, best.num)
                end)
                local endTime = tick() + 30
                while tick() < endTime and State.AutoQuestFull do
                    local mobs = getAllMobs()
                    if #mobs > 0 then
                        local hrp = char.HumanoidRootPart
                        local nearest, d = nil, math.huge
                        for _, m in ipairs(mobs) do
                            local dd = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if dd < d then nearest, d = m, dd end
                        end
                        if nearest then
                            flyTo(hrp, safePosition(nearest.HumanoidRootPart.CFrame, 3))
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then pcall(function() tool:Activate() end) end
                        end
                    end
                    task.wait(0.5)
                end
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("CompleteQuest") end)
            end
        end
    end
end)

-- ===== AUTO HAKI =====
task.spawn(function()
    while task.wait(1) do
        if State.AutoHaki and p.Character then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Ken", true) end)
        end
    end
end)

-- ===== AUTO CLICK =====
task.spawn(function()
    while task.wait(0.15) do
        if State.AutoClick then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- ===== ESP LOOPS =====
task.spawn(function()
    while task.wait(0.7) do
        if State.ESP_Mobs then
            for _, m in ipairs(getAllMobs()) do
                if not espObjects[m] then createESP(m, Color3.fromRGB(255, 60, 60)) end
            end
        end
        if State.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= p and plr.Character and not espObjects[plr.Character] then
                    local hp, maxHp, lvl, fruit = getPlayerInfo(plr)
                    local info = "HP: " .. hp .. "/" .. maxHp .. " | Lvl: " .. lvl .. " | " .. fruit
                    createESP(plr.Character, Color3.fromRGB(60, 220, 60), info)
                end
            end
        end
        if State.ESP_Fruits then
            for _, obj in ipairs(workspace:GetChildren()) do
                if isFruit(obj) and not espObjects[obj] then createESP(obj, Color3.fromRGB(255, 180, 60)) end
            end
        end
        if State.ESP_Berries then
            for _, obj in ipairs(recursiveFind(isBerry, 3)) do
                if not espObjects[obj] then createESP(obj, Color3.fromRGB(180, 100, 255)) end
            end
        end
        if State.ESP_Chests then
            for _, obj in ipairs(getAllChests()) do
                if not espObjects[obj] then createESP(obj, Color3.fromRGB(255, 220, 60)) end
            end
        end
    end
end)

-- Обновление HP/фрукта игроков каждые 0.3с
task.spawn(function()
    while task.wait(0.3) do
        if State.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= p and plr.Character and espObjects[plr.Character] then
                    local hp, maxHp, lvl, fruit = getPlayerInfo(plr)
                    local data = espObjects[plr.Character]
                    if data.subLbl then
                        data.subLbl.Text = "HP: " .. hp .. "/" .. maxHp .. " | Lvl: " .. lvl .. " | " .. fruit
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do updateESPLabels() end
end)

-- ===== ANTI-AFK =====
p.Idled:Connect(function()
    if getgenv().AntiAFK ~= false then
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end)

p.CharacterAdded:Connect(function(char)
    task.wait(1)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = Config.WalkSpeed end
end)

-- ===== DONE =====
game.StarterGui:SetCore("SendNotification", {
    Title = "BF Toolkit v7",
    Text = "Загружено. ESP Fix + Player Info.",
    Duration = 5
})
warn("[BF Toolkit v7] Загружено успешно")
