--[[
    Blox Fruits Advanced Toolkit v5 by Gta90988
    Медленный полёт | ESP fix | Разделение морей | Сундуки
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
    FlySpeed = 50,
    FlyTime = 1.0,         -- МЕДЛЕННЕЕ (было 0.35)
    AttackRadius = 40,
    FarmDelay = 0.5,
    MaxTargetDist = 500,
    AutoDetect = true,
    WalkSpeed = 16,
    CurrentSea = "Auto",
}

-- ===== ХЕЛПЕРЫ =====
local function randFloat(a, b)
    return a + math.random() * (b - a)
end

local function safePosition(targetCFrame, offsetDist)
    local angle = math.rad(math.random(0, 360))
    local ox = math.cos(angle) * offsetDist
    local oz = math.sin(angle) * offsetDist
    return targetCFrame * CFrame.new(ox, 0, oz)
end

-- Плавный полёт (медленнее для античита)
local function flyTo(hrp, targetCFrame, duration)
    duration = duration or Config.FlyTime
    if Config.AutoDetect then
        duration = duration * randFloat(0.9, 1.3)
    end
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {CFrame = targetCFrame}
    )
    tween:Play()
    tween.Completed:Wait()
end

-- ===== ОПРЕДЕЛЕНИЕ МОРЯ =====
local function getCurrentSea()
    if Config.CurrentSea ~= "Auto" then return Config.CurrentSea end
    
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 1 end
    local pos = char.HumanoidRootPart.Position
    
    -- Второе море: Kingdom of Rose, Cafe и рядом
    -- Третье море: Port Town, Hydra, Great Tree и выше
    -- Первое море: всё остальное
    
    -- Простое определение по Y-координате и позиции
    if pos.Z > 4000 or pos.X > 4000 then
        return 3  -- Третье море (Port Town, Hydra и т.д.)
    elseif pos.Z < -1000 or (pos.X > -500 and pos.X < 1500 and pos.Z > -2500 and pos.Z < 1000) then
        return 2  -- Второе море (Cafe, Kingdom of Rose)
    else
        return 1  -- Первое море
    end
end

-- ===== ПОИСК МОБОВ (ИСПРАВЛЕНО) =====
local function isMob(m)
    if not m or m == p.Character then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    local hum = m:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and m:FindFirstChild("HumanoidRootPart")
end

-- Ищем мобов и в workspace, и в папках
local function getAllMobs()
    local mobs = {}
    -- Прямые дети workspace
    for _, m in ipairs(workspace:GetChildren()) do
        if isMob(m) then table.insert(mobs, m) end
    end
    -- Ищем в папках (Enemies, NPCs и т.д.)
    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, m in ipairs(folder:GetChildren()) do
                if isMob(m) then table.insert(mobs, m) end
            end
        end
    end
    return mobs
end

local function getMobsInRadius(center, radius)
    local list = {}
    for _, m in ipairs(getAllMobs()) do
        local d = (m.HumanoidRootPart.Position - center).Magnitude
        if d <= radius then
            table.insert(list, {mob = m, dist = d})
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function getNearestMob(maxDist)
    maxDist = maxDist or Config.MaxTargetDist
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, m in ipairs(getAllMobs()) do
        local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
        if d < dist and d < maxDist then best, dist = m, d end
    end
    return best, dist
end

-- ===== ФРУКТЫ =====
local FRUITS = {
    ["Rocket"]=true,["Spin"]=true,["Chop"]=true,["Spring"]=true,["Bomb"]=true,
    ["Smoke"]=true,["Spike"]=true,["Flame"]=true,["Falcon"]=true,["Ice"]=true,
    ["Sand"]=true,["Dark"]=true,["Diamond"]=true,["Light"]=true,["Rubber"]=true,
    ["Barrier"]=true,["Magma"]=true,["Door"]=true,["Quake"]=true,["Buddha"]=true,
    ["Love"]=true,["Spider"]=true,["Sound"]=true,["Phoenix"]=true,["Portal"]=true,
    ["Rumble"]=true,["Pain"]=true,["Blizzard"]=true,["Gravity"]=true,["Mammoth"]=true,
    ["T-Rex"]=true,["Dough"]=true,["Shadow"]=true,["Venom"]=true,["Control"]=true,
    ["Spirit"]=true,["Dragon"]=true,["Leopard"]=true,["Kitsune"]=true,
}
local FRUIT_RARITY = {
    ["Rocket"]="Common",["Spin"]="Common",["Chop"]="Common",["Spring"]="Common",["Bomb"]="Common",
    ["Smoke"]="Uncommon",["Spike"]="Uncommon",["Flame"]="Uncommon",["Falcon"]="Uncommon",["Ice"]="Uncommon",
    ["Sand"]="Rare",["Dark"]="Rare",["Diamond"]="Rare",["Light"]="Rare",["Rubber"]="Rare",["Barrier"]="Rare",["Magma"]="Rare",
    ["Door"]="Legendary",["Quake"]="Legendary",["Buddha"]="Legendary",["Love"]="Legendary",["Spider"]="Legendary",
    ["Sound"]="Legendary",["Phoenix"]="Legendary",["Portal"]="Legendary",["Rumble"]="Legendary",["Pain"]="Legendary",["Blizzard"]="Legendary",
    ["Gravity"]="Mythical",["Mammoth"]="Mythical",["T-Rex"]="Mythical",["Dough"]="Mythical",["Shadow"]="Mythical",
    ["Venom"]="Mythical",["Control"]="Mythical",["Spirit"]="Mythical",["Dragon"]="Mythical",["Leopard"]="Mythical",["Kitsune"]="Mythical",
}
local RARITY_COLOR = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(120, 220, 120),
    Rare      = Color3.fromRGB(80, 150, 255),
    Legendary = Color3.fromRGB(255, 180, 60),
    Mythical  = Color3.fromRGB(255, 70, 120),
}

local BERRY_TYPES = {
    ["Green Toad Berry"]="Green Toad",["White Cloud Berry"]="White Cloud",
    ["Blue Icicle Berry"]="Blue Icicle",["Purple Jelly Berry"]="Purple Jelly",
    ["Pink Pig Berry"]="Pink Pig",["Orange Berry"]="Orange",
    ["Yellow Star Berry"]="Yellow Star",["Red Cherry Berry"]="Red Cherry",
}

local function isFruit(obj)
    return obj:IsA("Tool") and obj:FindFirstChild("Handle") and FRUITS[obj.Name]
end
local function isBerry(obj) return BERRY_TYPES[obj.Name] ~= nil end
local function isChest(obj)
    local n = obj.Name:lower()
    return n:find("chest") or n:find("treasure") or n:find("crate")
end

-- ===== UI =====
local sg = Instance.new("ScreenGui")
sg.Name = "BF_Toolkit_v5"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = p:WaitForChild("PlayerGui")
getgenv().BF_TOOLKIT = sg

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 540, 0, 440)
main.Position = UDim2.new(0.5, -270, 0.5, -220)
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
titleLbl.Text = "BF Toolkit v5 | Slow Fly + Sea Auto"
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
    b.Size = UDim2.new(0, 72, 0, 28)
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
    tx = tx + 76
    pages[name] = makePage()
end
switchTab("Farm")

-- UI Хелперы
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
    Fly = false, AutoQuest = false, AutoChest = false
}

-- ===== ESP (ИСПРАВЛЕНО) =====
local espObjects = {}

local function destroyESP(obj)
    if espObjects[obj] then
        for _, v in pairs(espObjects[obj]) do
            if v and typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
        end
        espObjects[obj] = nil
    end
end

local function createESP(obj, color, isFruitType, rarity)
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
    bb.Size = UDim2.new(0, 220, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = obj

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = obj.Name
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    data.bb = bb
    data.lbl = lbl
    data.baseName = obj.Name

    if isFruitType and rarity then
        local rl = Instance.new("TextLabel", bb)
        rl.Size = UDim2.new(1, 0, 0, 14)
        rl.Position = UDim2.new(0, 0, 1, 0)
        rl.BackgroundTransparency = 1
        rl.Text = "[" .. rarity .. "]"
        rl.TextColor3 = RARITY_COLOR[rarity] or color
        rl.TextStrokeTransparency = 0
        rl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        rl.Font = Enum.Font.GothamBold
        rl.TextSize = 12
        data.rarityLbl = rl
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
addToggle(farmPage, "Bring Mobs (притягивать)", function(v) State.BringMobs = v end)
addToggle(farmPage, "Auto Haki (Buso + Ken)", function(v) State.AutoHaki = v end)
addToggle(farmPage, "Auto Click", function(v) State.AutoClick = v end)
addToggle(farmPage, "Auto Chest (полёт к сундукам)", function(v) State.AutoChest = v end)
addSlider(farmPage, "Зона атаки", 5, 200, 40, function(v) Config.AttackRadius = v end)
addSlider(farmPage, "Задержка атаки (x0.1с)", 1, 20, 5, function(v) Config.FarmDelay = v * 0.1 end)
addSlider(farmPage, "Время полёта (x0.1с) [АНТИ-КИК]", 3, 30, 10, function(v) Config.FlyTime = v * 0.1 end)

addButton(farmPage, "ТП к ближайшему мобу (медленно)", function()
    local mob = getNearestMob()
    if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        flyTo(p.Character.HumanoidRootPart, safePosition(mob.HumanoidRootPart.CFrame, 3))
    end
end)

addButton(farmPage, "ТП к ближайшему сундуку", function()
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, obj in ipairs(workspace:GetChildren()) do
        if isChest(obj) and obj:FindFirstChild("Handle") then
            local d = (obj.Handle.Position - hrp.Position).Magnitude
            if d < dist then best, dist = obj, d end
        end
    end
    if best then
        flyTo(hrp, best.Handle.CFrame * CFrame.new(0, 0, 3))
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "Сундуки",
            Text = "Рядом нет сундуков",
            Duration = 3
        })
    end
end)

-- ===== SEA TAB (РАЗДЕЛЕНИЕ МОРЕЙ) =====
local seaPage = pages.Sea

-- Квестовые NPC по морям (на основе гайдов)
local QuestNPCs = {
    -- ПЕРВОЕ МОРЕ
    [1] = {
        {name = "Bandit",    cframe = CFrame.new(-1500, 10, 100),   quest = "BanditQuest1",   num = 1, lvl = 1},
        {name = "Monkey",    cframe = CFrame.new(-1500, 20, 200),   quest = "JungleQuest",    num = 1, lvl = 10},
        {name = "Pirate",    cframe = CFrame.new(-1200, 20, 3300),  quest = "PirateQuest",    num = 1, lvl = 30},
        {name = "Brute",     cframe = CFrame.new(-1300, 20, 4300),  quest = "DesertQuest",    num = 1, lvl = 60},
        {name = "Snow Bandit",cframe= CFrame.new(-1100, 20, 5800),  quest = "SnowQuest",      num = 1, lvl = 90},
    },
    -- ВТОРОЕ МОРЕ
    [2] = {
        {name = "Swan Pirate",cframe= CFrame.new(-400, 30, 2000),   quest = "SwanQuest",      num = 1, lvl = 700},
        {name = "Zombie",     cframe = CFrame.new(-4000, 30, -5000), quest = "ZombieQuest",    num = 1, lvl = 1000},
        {name = "Ice Pirate", cframe = CFrame.new(500, 30, -1500),  quest = "IceQuest",       num = 1, lvl = 1200},
    },
    -- ТРЕТЬЕ МОРЕ
    [3] = {
        {name = "Port Pirate",cframe= CFrame.new(-300, 20, 5000),   quest = "PortQuest",      num = 1, lvl = 1500},
        {name = "Hydra Crew", cframe = CFrame.new(5000, 30, 1000),  quest = "HydraQuest",     num = 1, lvl = 1575},
        {name = "Tree NPC",   cframe = CFrame.new(2000, 50, -2000), quest = "TreeQuest",      num = 1, lvl = 1700},
    }
}

-- Индикатор текущего моря
local seaIndicator = Instance.new("TextLabel", seaPage)
seaIndicator.Size = UDim2.new(1, -10, 0, 30)
seaIndicator.Position = UDim2.new(0, 5, 0, 5)
seaIndicator.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
seaIndicator.TextColor3 = Color3.fromRGB(100, 200, 255)
seaIndicator.Font = Enum.Font.GothamBold
seaIndicator.TextSize = 14
seaIndicator.BorderSizePixel = 0
seaIndicator.Text = "Текущее море: определение..."
Instance.new("UICorner", seaIndicator).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    while task.wait(2) do
        local sea = getCurrentSea()
        seaIndicator.Text = "Текущее море: " .. sea .. " | Уровень: " .. (p.Data and p.Data.Level.Value or "?")
    end
end)

-- Кнопки выбора моря
addButton(seaPage, "Установить: Авто-определение", function()
    Config.CurrentSea = "Auto"
end, Color3.fromRGB(100, 180, 100))

addButton(seaPage, "Установить: Первое море", function()
    Config.CurrentSea = 1
end, Color3.fromRGB(100, 130, 200))

addButton(seaPage, "Установить: Второе море", function()
    Config.CurrentSea = 2
end, Color3.fromRGB(100, 130, 200))

addButton(seaPage, "Установить: Третье море", function()
    Config.CurrentSea = 3
end, Color3.fromRGB(100, 130, 200))

-- Кнопки квестов для текущего моря
addButton(seaPage, "Взять квест для моего уровня", function()
    local sea = getCurrentSea()
    local lvl = p.Data and p.Data.Level.Value or 1
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
        game.StarterGui:SetCore("SendNotification", {
            Title = "Квест взят",
            Text = best.name .. " (море " .. sea .. ")",
            Duration = 3
        })
    end
end, Color3.fromRGB(150, 100, 200))

addButton(seaPage, "Отменить квест", function()
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
    end)
end)

-- ===== VISUAL TAB =====
local visualPage = pages.Visual
addToggle(visualPage, "ESP Мобы (красные)", function(v)
    State.ESP_Mobs = v
    if not v then for obj in pairs(espObjects) do destroyESP(obj) end end
end)
addToggle(visualPage, "ESP Игроки (зелёные)", function(v)
    State.ESP_Players = v
    if not v then for obj in pairs(espObjects) do destroyESP(obj) end end
end)
addToggle(visualPage, "ESP Фрукты (тип + редкость)", function(v)
    State.ESP_Fruits = v
    if not v then for obj in pairs(espObjects) do destroyESP(obj) end end
end)
addToggle(visualPage, "ESP Ягоды для ауры", function(v)
    State.ESP_Berries = v
    if not v then for obj in pairs(espObjects) do destroyESP(obj) end end
end)
addToggle(visualPage, "ESP Сундуки", function(v)
    State.ESP_Chests = v
    if not v then for obj in pairs(espObjects) do destroyESP(obj) end end
end)

-- ===== TELEPORT TAB =====
local tpPage = pages.Teleport
local ISLANDS = {
    [1] = {
        ["Starter Island"]=CFrame.new(0,20,0),["Marine Fortress"]=CFrame.new(-2500,30,-2500),
        ["Middle Town"]=CFrame.new(-600,15,600),["Jungle"]=CFrame.new(-1500,20,200),
        ["Pirate Village"]=CFrame.new(-1200,20,3300),["Desert"]=CFrame.new(-1300,20,4300),
        ["Frozen Village"]=CFrame.new(-1100,20,5800),
    },
    [2] = {
        ["Cafe"]=CFrame.new(-380,15,260),["Kingdom of Rose"]=CFrame.new(-400,30,2000),
        ["Green Zone"]=CFrame.new(100,20,500),["Graveyard"]=CFrame.new(-4000,30,-5000),
        ["Ice Castle"]=CFrame.new(500,30,-1500),
    },
    [3] = {
        ["Port Town"]=CFrame.new(-300,20,5000),["Hydra Island"]=CFrame.new(5000,30,1000),
        ["Great Tree"]=CFrame.new(2000,50,-2000),["Floating Turtle"]=CFrame.new(3000,30,3000),
    }
}

addSlider(tpPage, "Скорость ТП (x0.1с) [АНТИ-КИК]", 5, 50, 12, function(v) Config.FlyTime = v * 0.1 end)

addButton(tpPage, "ТП к ближайшему мобу", function()
    local mob = getNearestMob()
    if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        flyTo(p.Character.HumanoidRootPart, safePosition(mob.HumanoidRootPart.CFrame, 3))
    end
end)

addButton(tpPage, "ТП к ближайшему сундуку", function()
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local best, dist = nil, math.huge
    for _, obj in ipairs(workspace:GetChildren()) do
        if isChest(obj) and obj:FindFirstChild("Handle") then
            local d = (obj.Handle.Position - hrp.Position).Magnitude
            if d < dist then best, dist = obj, d end
        end
    end
    if best then flyTo(hrp, best.Handle.CFrame * CFrame.new(0, 0, 3)) end
end)

-- Кнопки островов по морям
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
addSlider(movePage, "Fly Speed", 20, 200, 50, function(v) Config.FlySpeed = v end)

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
            flyVel.Velocity = move * Config.FlySpeed
            flyGyro.CFrame = cam.CFrame
        end
    end
end)

-- ===== MISC TAB =====
local miscPage = pages.Misc
addToggle(miscPage, "Anti-AFK", function(v) getgenv().AntiAFK = v end)
addToggle(miscPage, "Anti-Detect (рандомизация)", function(v) Config.AutoDetect = v end)

addButton(miscPage, "Показать FPS / Ping", function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    game.StarterGui:SetCore("SendNotification", {
        Title = "Info",
        Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms",
        Duration = 5
    })
end)

addButton(miscPage, "Респавн", function()
    if p.Character then p.Character:BreakJoints() end
end, Color3.fromRGB(180, 100, 100))

-- ===== ГЛАВНЫЙ ЦИКЛ АВТОФАРМА =====
task.spawn(function()
    while task.wait(Config.FarmDelay) do
        if State.AutoFarm then
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                task.wait(1)
                continue
            end
            local hrp = char.HumanoidRootPart
            local mobs = getMobsInRadius(hrp.Position, Config.AttackRadius)
            if #mobs > 0 then
                local target = mobs[1].mob
                flyTo(hrp, safePosition(target.HumanoidRootPart.CFrame, 3))
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(Config.FarmDelay * 0.3)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            else
                local mob = getNearestMob(Config.MaxTargetDist)
                if mob then flyTo(hrp, safePosition(mob.HumanoidRootPart.CFrame, 3)) end
            end
        end
    end
end)

-- ===== AUTO CHEST LOOP =====
task.spawn(function()
    while task.wait(2) do
        if State.AutoChest then
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local hrp = char.HumanoidRootPart
            local best, dist = nil, math.huge
            for _, obj in ipairs(workspace:GetChildren()) do
                if isChest(obj) and obj:FindFirstChild("Handle") then
                    local d = (obj.Handle.Position - hrp.Position).Magnitude
                    if d < dist and d < 300 then best, dist = obj, d end
                end
            end
            if best then flyTo(hrp, best.Handle.CFrame * CFrame.new(0, 0, 3)) end
        end
    end
end)

-- ===== AUTO QUEST LOOP =====
task.spawn(function()
    while task.wait(3) do
        if State.AutoQuest then
            local char = p.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local sea = getCurrentSea()
            local lvl = p.Data and p.Data.Level.Value or 1
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

-- ===== ESP LOOPS (ИСПРАВЛЕНО) =====
task.spawn(function()
    while task.wait(0.7) do
        if State.ESP_Mobs then
            for _, m in ipairs(getAllMobs()) do
                if not espObjects[m] then
                    createESP(m, Color3.fromRGB(255, 60, 60))
                end
            end
        end
        if State.ESP_Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= p and plr.Character and not espObjects[plr.Character] then
                    createESP(plr.Character, Color3.fromRGB(60, 220, 60))
                end
            end
        end
        if State.ESP_Fruits then
            for _, obj in ipairs(workspace:GetChildren()) do
                if isFruit(obj) and not espObjects[obj] then
                    local rarity = FRUIT_RARITY[obj.Name] or "Common"
                    local color = RARITY_COLOR[rarity] or Color3.fromRGB(255, 180, 60)
                    createESP(obj, color, true, rarity)
                end
            end
        end
        if State.ESP_Berries then
            for _, obj in ipairs(workspace:GetChildren()) do
                if isBerry(obj) and not espObjects[obj] then
                    createESP(obj, Color3.fromRGB(180, 100, 255))
                end
            end
        end
        if State.ESP_Chests then
            for _, obj in ipairs(workspace:GetChildren()) do
                if isChest(obj) and not espObjects[obj] then
                    createESP(obj, Color3.fromRGB(255, 220, 60))
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        updateESPLabels()
    end
end)

-- ===== ANTI-AFK =====
p.Idled:Connect(function()
    if getgenv().AntiAFK ~= false then
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end)

-- ===== WALKSPEED ON RESPAWN =====
p.CharacterAdded:Connect(function(char)
    task.wait(1)
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = Config.WalkSpeed end
end)

-- ===== DONE =====
game.StarterGui:SetCore("SendNotification", {
    Title = "BF Toolkit v5",
    Text = "Загружено. Медленный полёт + разделение морей.",
    Duration = 5
})
warn("[BF Toolkit v5] Загружено успешно")
