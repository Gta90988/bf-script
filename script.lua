--[[
    ╔══════════════════════════════════════════╗
    ║         GOSHA HUB v1.0                   ║
    ║         by Gta90988                      ║
    ╚══════════════════════════════════════════╝
]]

if getgenv().GOSHA_HUB then pcall(function() getgenv().GOSHA_HUB:Destroy() end) end
if getgenv().GOSHA_CLEANUP then pcall(getgenv().GOSHA_CLEANUP) end
getgenv().GOSHA_RUNNING = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local p = Players.LocalPlayer

-- ===== КОНФИГ =====
local Config = {
    FlyTime = 1.5,
    AttackRadius = 50,
    FarmDelay = 0.5,
    AutoDetect = true,
    WalkSpeed = 16,
    CurrentSea = "Auto",
    Weapon = "Auto",
    FollowTarget = nil,
}

local function randFloat(a, b) return a + math.random() * (b - a) end
local function safePosition(cf, dist)
    local a = math.rad(math.random(0, 360))
    return cf * CFrame.new(math.cos(a) * dist, 0, math.sin(a) * dist)
end
local function flyTo(hrp, target, duration)
    duration = duration or Config.FlyTime
    if Config.AutoDetect then duration = duration * randFloat(0.9, 1.3) end
    local tween = TweenService:Create(hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {CFrame = target})
    tween:Play()
    tween.Completed:Wait()
end

-- ===== РЕКУРСИВНЫЙ ПОИСК =====
local function recursiveFind(predicate, maxDepth)
    maxDepth = maxDepth or 6
    local found = {}
    local function scan(parent, depth)
        if depth > maxDepth then return end
        local children = parent:GetChildren()
        for i = 1, #children do
            local obj = children[i]
            if obj and obj.Parent then
                local ok, r = pcall(predicate, obj)
                if ok and r then table.insert(found, obj) end
                if obj:IsA("Folder") or obj:IsA("Model") then scan(obj, depth + 1) end
            end
        end
    end
    pcall(scan, workspace, 0)
    return found
end

-- ===== МОБЫ =====
local function isMob(m)
    if not m or m == p.Character then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    local hum = m:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and m:FindFirstChild("HumanoidRootPart")
end
local function getAllMobs() return recursiveFind(isMob, 3) end

-- ===== СУНДУКИ =====
local function isChest(obj)
    local n = obj.Name:lower()
    if not (n:find("chest") or n:find("treasure") or n:find("crate")) then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    return (obj:FindFirstChild("Handle") ~= nil) or (obj.PrimaryPart ~= nil)
end
local function getAllChests() return recursiveFind(isChest, 5) end

-- ===== ФРУКТЫ =====
local FRUITS = {["Rocket"]=true,["Spin"]=true,["Chop"]=true,["Spring"]=true,["Bomb"]=true,["Smoke"]=true,["Spike"]=true,["Flame"]=true,["Falcon"]=true,["Ice"]=true,["Sand"]=true,["Dark"]=true,["Diamond"]=true,["Light"]=true,["Rubber"]=true,["Barrier"]=true,["Magma"]=true,["Door"]=true,["Quake"]=true,["Buddha"]=true,["Love"]=true,["Spider"]=true,["Sound"]=true,["Phoenix"]=true,["Portal"]=true,["Rumble"]=true,["Pain"]=true,["Blizzard"]=true,["Gravity"]=true,["Mammoth"]=true,["T-Rex"]=true,["Dough"]=true,["Shadow"]=true,["Venom"]=true,["Control"]=true,["Spirit"]=true,["Dragon"]=true,["Leopard"]=true,["Kitsune"]=true}
local function isFruit(obj) return obj:IsA("Tool") and obj:FindFirstChild("Handle") and FRUITS[obj.Name] end

-- ===== ЯГОДЫ =====
local BERRY_TYPES = {["Green Toad Berry"]="Green Toad",["White Cloud Berry"]="White Cloud",["Blue Icicle Berry"]="Blue Icicle",["Purple Jelly Berry"]="Purple Jelly",["Pink Pig Berry"]="Pink Pig",["Orange Berry"]="Orange",["Yellow Star Berry"]="Yellow Star",["Red Cherry Berry"]="Red Cherry"}
local function isBerry(obj) return BERRY_TYPES[obj.Name] ~= nil end

-- ===== ОСТРОВА (ESP + TP) =====
local ISLANDS = {
    -- ПЕРВОЕ МОРЕ
    {name="Starter Island", cf=CFrame.new(0,20,0), sea=1},
    {name="Marine Fortress", cf=CFrame.new(-2500,30,-2500), sea=1},
    {name="Middle Town", cf=CFrame.new(-600,15,600), sea=1},
    {name="Jungle", cf=CFrame.new(-1500,20,200), sea=1},
    {name="Pirate Village", cf=CFrame.new(-1200,20,3300), sea=1},
    {name="Desert", cf=CFrame.new(-1300,20,4300), sea=1},
    {name="Frozen Village", cf=CFrame.new(-1100,20,5800), sea=1},
    {name="Colosseum", cf=CFrame.new(-1500,40,2000), sea=1},
    {name="Magma Village", cf=CFrame.new(-5200,30,1000), sea=1},
    {name="Underwater City", cf=CFrame.new(-4000,-200,5000), sea=1},
    {name="Fountain City", cf=CFrame.new(5200,30,4000), sea=1},
    {name="Skylands", cf=CFrame.new(-4500,800,-3000), sea=1},
    {name="Upper Skylands", cf=CFrame.new(-4000,1500,-3500), sea=1},
    -- ВТОРОЕ МОРЕ
    {name="Cafe", cf=CFrame.new(-380,15,260), sea=2},
    {name="Kingdom of Rose", cf=CFrame.new(-400,30,2000), sea=2},
    {name="Green Zone", cf=CFrame.new(100,20,500), sea=2},
    {name="Graveyard Island", cf=CFrame.new(-4000,30,-5000), sea=2},
    {name="Ice Castle", cf=CFrame.new(500,30,-1500), sea=2},
    {name="Snow Mountain", cf=CFrame.new(1000,50,-1000), sea=2},
    {name="Forgotten Island", cf=CFrame.new(-3000,20,-2000), sea=2},
    {name="Hot and Cold", cf=CFrame.new(-5000,30,-3000), sea=2},
    {name="Cursed Ship", cf=CFrame.new(1000,50,-2000), sea=2},
    -- ТРЕТЬЕ МОРЕ
    {name="Port Town", cf=CFrame.new(-300,20,5000), sea=3},
    {name="Hydra Island", cf=CFrame.new(5000,30,1000), sea=3},
    {name="Great Tree", cf=CFrame.new(2000,50,-2000), sea=3},
    {name="Floating Turtle", cf=CFrame.new(3000,30,3000), sea=3},
    {name="Tiki Outpost", cf=CFrame.new(-1000,20,-5000), sea=3},
    {name="Candy Cane Land", cf=CFrame.new(2000,30,3000), sea=3},
    {name="Prehistoric Island", cf=CFrame.new(5000,30,-4000), sea=3},
    {name="Haunted Castle", cf=CFrame.new(-5000,50,5000), sea=3},
    {name="Castle on the Sea", cf=CFrame.new(5000,30,-3000), sea=3},
}

-- ===== КВЕСТЫ =====
local QuestNPCs = {
    [1] = {
        {name="Bandit", cf=CFrame.new(-1500,10,100), quest="BanditQuest1", num=1, lvl=1},
        {name="Monkey", cf=CFrame.new(-1500,20,200), quest="JungleQuest", num=1, lvl=10},
        {name="Pirate", cf=CFrame.new(-1200,20,3300), quest="PirateQuest", num=1, lvl=30},
        {name="Brute", cf=CFrame.new(-1300,20,4300), quest="DesertQuest", num=1, lvl=60},
        {name="Snow Bandit", cf=CFrame.new(-1100,20,5800), quest="SnowQuest", num=1, lvl=90},
    },
    [2] = {
        {name="Swan Pirate", cf=CFrame.new(-400,30,2000), quest="SwanQuest", num=1, lvl=700},
        {name="Zombie", cf=CFrame.new(-4000,30,-5000), quest="ZombieQuest", num=1, lvl=1000},
        {name="Ice Pirate", cf=CFrame.new(500,30,-1500), quest="IceQuest", num=1, lvl=1200},
    },
    [3] = {
        {name="Port Pirate", cf=CFrame.new(-300,20,5000), quest="PortQuest", num=1, lvl=1500},
        {name="Hydra Crew", cf=CFrame.new(5000,30,1000), quest="HydraQuest", num=1, lvl=1575},
        {name="Tree NPC", cf=CFrame.new(2000,50,-2000), quest="TreeQuest", num=1, lvl=1700},
    }
}

-- ===== МОРЕ =====
local function getCurrentSea()
    if Config.CurrentSea ~= "Auto" then return Config.CurrentSea end
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 1 end
    local pos = char.HumanoidRootPart.Position
    if pos.Z > 4000 or pos.X > 4000 then return 3
    elseif pos.Z > -1000 and pos.Z < 3000 and pos.X > -1000 and pos.X < 1500 then return 2
    else return 1 end
end

-- ===== ИНФО ИГРОКА =====
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
sg.Name = "GoshaHUB"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = p:WaitForChild("PlayerGui")
getgenv().GOSHA_HUB = sg

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 580, 0, 470)
main.Position = UDim2.new(0.5, -290, 0.5, -235)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

-- Градиентный заголовок
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local gradient = Instance.new("UIGradient", titleBar)
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 130, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 80, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 150)),
}
gradient.Rotation = 15

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, -140, 1, 0)
titleLbl.Position = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "✦ GOSHA HUB v1.0"
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 17
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local resetBtn = Instance.new("TextButton", titleBar)
resetBtn.Size = UDim2.new(0, 60, 0, 28)
resetBtn.Position = UDim2.new(1, -98, 0, 8)
resetBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 11
resetBtn.BorderSizePixel = 0
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
    getgenv().GOSHA_RUNNING = false
    if getgenv().GOSHA_CLEANUP then pcall(getgenv().GOSHA_CLEANUP) end
    sg:Destroy()
end)

resetBtn.MouseButton1Click:Connect(function()
    getgenv().GOSHA_RUNNING = false
    if getgenv().GOSHA_CLEANUP then pcall(getgenv().GOSHA_CLEANUP) end
    game.StarterGui:SetCore("SendNotification", {Title="RESET", Text="Очищено. Запусти скрипт заново.", Duration=3})
    sg:Destroy()
end)

-- Вкладки
local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -20, 0, 32)
tabBar.Position = UDim2.new(0, 10, 0, 52)
tabBar.BackgroundTransparency = 1

local tabNames = {"Farm", "Quest", "Visual", "Islands", "Players", "Move", "Misc"}
local tabs, pages, activeTab = {}, {}, nil

local function makePage()
    local pg = Instance.new("ScrollingFrame", main)
    pg.Size = UDim2.new(1, -20, 1, -98)
    pg.Position = UDim2.new(0, 10, 0, 92)
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
    if activeTab then 
        TweenService:Create(activeTab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 40)}):Play()
    end
    activeTab = tabs[name]
    TweenService:Create(activeTab, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 130, 220)}):Play()
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
end

local tx = 0
for _, name in ipairs(tabNames) do
    local b = Instance.new("TextButton", tabBar)
    b.Size = UDim2.new(0, 76, 0, 28)
    b.Position = UDim2.new(0, tx, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    tabs[name] = b
    tx = tx + 79
    pages[name] = makePage()
end
switchTab("Farm")

-- UI Helpers
local function addButton(parent, text, cb, color)
    color = color or Color3.fromRGB(60, 130, 220)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 34)
    btn.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 40)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    btn.MouseButton1Click:Connect(function() pcall(cb) end)
    return btn
end

local function addToggle(parent, text, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 34)
    f.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 40)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -80, 1, 0)
    l.Position = UDim2.new(0, 14, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(225, 225, 225)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    local state = false
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 60, 0, 24)
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
        TweenService:Create(b, TweenInfo.new(0.15), 
            {BackgroundColor3 = state and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(200, 50, 50)}):Play()
        pcall(cb, state)
    end)
    return f
end

local function addSlider(parent, text, min, max, default, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 52)
    f.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 58)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 14, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(225, 225, 225)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    local slider = Instance.new("Frame", f)
    slider.Size = UDim2.new(1, -28, 0, 6)
    slider.Position = UDim2.new(0, 14, 0, 34)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    slider.BorderSizePixel = 0
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
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

local function addDropdown(parent, text, options, default, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 34)
    f.Position = UDim2.new(0, 5, 0, 5 + (#parent:GetChildren() - 1) * 40)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -140, 1, 0)
    l.Position = UDim2.new(0, 14, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(225, 225, 225)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    local current = default
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 120, 0, 24)
    b.Position = UDim2.new(1, -130, 0, 5)
    b.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
    b.Text = current
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local idx = 1
    for i, opt in ipairs(options) do
        if opt == default then idx = i break end
    end
    b.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        current = options[idx]
        b.Text = current
        pcall(cb, current)
    end)
    return f
end

-- ===== STATE =====
local State = {
    AutoFarm = false, BringMobs = false, AutoHaki = false,
    AutoClick = false, AutoQuestFull = false, AutoChest = false,
    ESP_Mobs = false, ESP_Players = false, ESP_Fruits = false,
    ESP_Berries = false, ESP_Chests = false, ESP_Islands = false,
    ESP_Mirage = false, Fly = false
}

-- ===== ESP =====
getgenv().GOSHA_ESP = {}
local espObjects = getgenv().GOSHA_ESP

local function destroyESP(obj)
    if espObjects[obj] then
        pcall(function() if espObjects[obj].hl then espObjects[obj].hl:Destroy() end end)
        pcall(function() if espObjects[obj].bb then espObjects[obj].bb:Destroy() end end)
        espObjects[obj] = nil
    end
end

getgenv().GOSHA_CLEANUP = function()
    local count = 0
    for obj, _ in pairs(espObjects) do
        pcall(function()
            if espObjects[obj].hl then espObjects[obj].hl:Destroy() end
            if espObjects[obj].bb then espObjects[obj].bb:Destroy() end
        end)
        espObjects[obj] = nil
        count = count + 1
    end
    pcall(function()
        for _, v in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if v:IsA("Highlight") then v:Destroy() end
        end
    end)
    return count
end

local function createESP(obj, color, extraLine)
    if not obj or not obj.Parent then return end
    if espObjects[obj] then return end
    pcall(function()
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
    end)
end

local function updateESPLabels()
    local myChar = p.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myPos = myChar.HumanoidRootPart.Position
    for obj, data in pairs(espObjects) do
        if not obj or not obj.Parent then destroyESP(obj) continue end
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle") or obj.PrimaryPart
        if root and data.lbl then
            local d = math.floor((root.Position - myPos).Magnitude)
            data.lbl.Text = data.baseName .. " [" .. d .. "m]"
        end
    end
end

-- ===== ВЫБОР ОРУЖИЯ =====
local function getWeapon()
    local char = p.Character
    if not char then return nil end
    local weapons = char:GetChildren()
    local melee, sword, gun, fruit = nil, nil, nil, nil
    for _, w in ipairs(weapons) do
        if w:IsA("Tool") then
            local wt = w.ToolTip:lower()
            if wt:find("melee") or wt:find("combat") then melee = w end
            if wt:find("sword") or wt:find("blade") then sword = w end
            if wt:find("gun") or wt:find("pistol") then gun = w end
            if FRUITS[w.Name] then fruit = w end
        end
    end
    
    if Config.Weapon == "Melee" and melee then return melee end
    if Config.Weapon == "Sword" and sword then return sword end
    if Config.Weapon == "Gun" and gun then return gun end
    if Config.Weapon == "Fruit" and fruit then return fruit end
    
    -- Auto — выбирает лучшее доступное
    if Config.Weapon == "Auto" then
        local best = fruit or sword or melee or gun
        if best then return best end
    end
    
    local anyTool = char:FindFirstChildOfClass("Tool")
    return anyTool
end

-- ===== FARM TAB =====
local farmPage = pages.Farm
addToggle(farmPage, "AutoFarm (плавный)", function(v) State.AutoFarm = v end)
addToggle(farmPage, "Bring Mobs", function(v) State.BringMobs = v end)
addToggle(farmPage, "Auto Haki (Buso + Ken)", function(v) State.AutoHaki = v end)
addToggle(farmPage, "Auto Click", function(v) State.AutoClick = v end)
addToggle(farmPage, "Auto Chest (работает)", function(v) State.AutoChest = v end)
addDropdown(farmPage, "Оружие", {"Auto", "Melee", "Sword", "Gun", "Fruit"}, "Auto", function(v) Config.Weapon = v end)
addSlider(farmPage, "Зона атаки", 5, 200, 50, function(v) Config.AttackRadius = v end)
addSlider(farmPage, "Задержка (x0.1с)", 1, 20, 5, function(v) Config.FarmDelay = v * 0.1 end)
addSlider(farmPage, "Время полёта (x0.1с)", 5, 30, 15, function(v) Config.FlyTime = v * 0.1 end)

addButton(farmPage, "ТП к мобу (плавно)", function()
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

addButton(farmPage, "ТП к сундуку", function()
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
    end
end)

-- ===== QUEST TAB =====
local questPage = pages.Quest

local questStatus = Instance.new("TextLabel", questPage)
questStatus.Size = UDim2.new(1, -10, 0, 32)
questStatus.Position = UDim2.new(0, 5, 0, 5)
questStatus.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
questStatus.TextColor3 = Color3.fromRGB(100, 220, 255)
questStatus.Font = Enum.Font.GothamBold
questStatus.TextSize = 13
questStatus.BorderSizePixel = 0
questStatus.Text = "Море: ? | Уровень: ?"
Instance.new("UICorner", questStatus).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    while getgenv().GOSHA_RUNNING do
        task.wait(2)
        local sea = getCurrentSea()
        local lvl = "?"
        pcall(function() lvl = p.Data.Level.Value end)
        questStatus.Text = "Море: " .. sea .. " | Уровень: " .. lvl
    end
end)

addToggle(questPage, "Auto Quest (полный цикл)", function(v) State.AutoQuestFull = v end)
addButton(questPage, "Взять квест сейчас", function()
    local sea = getCurrentSea()
    local lvl = 1
    pcall(function() lvl = p.Data.Level.Value end)
    local quests = QuestNPCs[sea] or {}
    local best = nil
    for _, q in ipairs(quests) do
        if lvl >= q.lvl then best = q end
    end
    if best and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        flyTo(p.Character.HumanoidRootPart, best.cf * CFrame.new(0, 0, 5), 1.5)
        task.wait(0.5)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", best.quest, best.num)
        end)
        game.StarterGui:SetCore("SendNotification", {Title="Квест взят", Text=best.name, Duration=3})
    end
end, Color3.fromRGB(150, 100, 220))

addButton(questPage, "Сдать квест", function()
    pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("CompleteQuest") end)
end, Color3.fromRGB(100, 180, 100))

-- ===== VISUAL TAB =====
local visualPage = pages.Visual

addToggle(visualPage, "ESP Мобы", function(v)
    State.ESP_Mobs = v
    if not v then for obj, _ in pairs(espObjects) do if isMob(obj) then destroyESP(obj) end end end
end)
addToggle(visualPage, "ESP Игроки (HP+LVL+FRUIT)", function(v)
    State.ESP_Players = v
    if not v then for obj, _ in pairs(espObjects) do if Players:GetPlayerFromCharacter(obj) then destroyESP(obj) end end end
end)
addToggle(visualPage, "ESP Фрукты (с редкостью)", function(v)
    State.ESP_Fruits = v
    if not v then for obj, _ in pairs(espObjects) do if isFruit(obj) then destroyESP(obj) end end end
end)
addToggle(visualPage, "ESP Ягоды", function(v)
    State.ESP_Berries = v
    if not v then for obj, _ in pairs(espObjects) do if isBerry(obj) then destroyESP(obj) end end end
end)
addToggle(visualPage, "ESP Сундуки", function(v)
    State.ESP_Chests = v
    if not v then for obj, _ in pairs(espObjects) do if isChest(obj) then destroyESP(obj) end end end
end)
addToggle(visualPage, "ESP Острова (название + дистанция)", function(v)
    State.ESP_Islands = v
    if not v then
        for _, isl in ipairs(ISLANDS) do
            if espObjects[isl.cf] then destroyESP(isl.cf) end
        end
    end
end)

addButton(visualPage, "ВЫКЛЮЧИТЬ ВСЁ ESP", function()
    local count = getgenv().GOSHA_CLEANUP()
    State.ESP_Mobs = false
    State.ESP_Players = false
    State.ESP_Fruits = false
    State.ESP_Berries = false
    State.ESP_Chests = false
    State.ESP_Islands = false
    game.StarterGui:SetCore("SendNotification", {Title="ESP", Text="Очищено: " .. count, Duration=3})
end, Color3.fromRGB(180, 100, 100))

-- ===== ISLANDS TAB =====
local islandsPage = pages.Islands

addButton(islandsPage, "Авто-определение моря", function() Config.CurrentSea = "Auto" end, Color3.fromRGB(100, 180, 100))

for _, isl in ipairs(ISLANDS) do
    addButton(islandsPage, "[" .. isl.sea .. "] " .. isl.name, function()
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            flyTo(p.Character.HumanoidRootPart, isl.cf)
            game.StarterGui:SetCore("SendNotification", {Title="ТП", Text=isl.name, Duration=2})
        end
    end, Color3.fromRGB(70 + isl.sea * 30, 100, 180))
end

-- ===== PLAYERS TAB =====
local playersPage = pages.Players

local playerList = Instance.new("ScrollingFrame", playersPage)
playerList.Size = UDim2.new(1, -10, 0, 200)
playerList.Position = UDim2.new(0, 5, 0, 5)
playerList.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 4
Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 6)

local function refreshPlayerList()
    for _, c in ipairs(playerList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local y = 5
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= p then
            local btn = Instance.new("TextButton", playerList)
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, y)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            btn.Text = plr.Name .. " (Lvl " .. (plr.Data and plr.Data.Level.Value or "?") .. ")"
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(function()
                Config.FollowTarget = plr
                game.StarterGui:SetCore("SendNotification", {Title="Наблюдение", Text="Следим за " .. plr.Name, Duration=3})
            end)
            y = y + 35
        end
    end
    playerList.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function() task.wait(1) refreshPlayerList() end)
task.spawn(function() task.wait(2) refreshPlayerList() end)

addButton(playersPage, "Обновить список", refreshPlayerList)
addButton(playersPage, "Следить за игроком (нажми на ник выше)", function()
    game.StarterGui:SetCore("SendNotification", {Title="Наблюдение", Text="Выбери игрока в списке", Duration=3})
end, Color3.fromRGB(150, 100, 220))
addButton(playersPage, "Прекратить наблюдение", function()
    Config.FollowTarget = nil
    if p.Character then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then workspace.CurrentCamera.CameraSubject = hrp end
    end
end, Color3.fromRGB(180, 100, 100))

-- Слежение за игроком
task.spawn(function()
    while getgenv().GOSHA_RUNNING do
        task.wait(0.2)
        if Config.FollowTarget and Config.FollowTarget.Character then
            local target = Config.FollowTarget.Character:FindFirstChild("HumanoidRootPart")
            if target then
                workspace.CurrentCamera.CameraSubject = target
            end
        end
    end
end)

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
            flyVel.Velocity = move * 60
            flyGyro.CFrame = cam.CFrame
        end
    end
end)

-- ===== MISC TAB =====
local miscPage = pages.Misc
addToggle(miscPage, "Anti-AFK", function(v) getgenv().AntiAFK = v end)
addButton(miscPage, "Показать FPS / Ping", function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    game.StarterGui:SetCore("SendNotification", {Title="Info", Text="FPS: " .. fps .. " | Ping: " .. ping .. "ms", Duration=5})
end)
addButton(miscPage, "Респавн", function()
    if p.Character then p.Character:BreakJoints() end
end, Color3.fromRGB(180, 100, 100))

-- ===== ОСНОВНОЙ ЦИКЛ =====
task.spawn(function()
    local lastESP, lastLabel, lastFarm = 0, 0, 0
    
    while getgenv().GOSHA_RUNNING do
        task.wait(0.1)
        local now = tick()
        
        -- ESP
        if now - lastESP > 0.7 then
            lastESP = now
            
            if State.ESP_Mobs then
                for _, m in ipairs(getAllMobs()) do
                    if not espObjects[m] then createESP(m, Color3.fromRGB(255, 60, 60)) end
                end
            end
            
            if State.ESP_Players then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= p and plr.Character and not espObjects[plr.Character] then
                        local hp, maxHp, lvl, fruit = getPlayerInfo(plr)
                        createESP(plr.Character, Color3.fromRGB(60, 220, 60), "HP:" .. hp .. " Lvl:" .. lvl .. " " .. fruit)
                    end
                end
            end
            
            if State.ESP_Fruits then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if isFruit(obj) and not espObjects[obj] then
                        createESP(obj, Color3.fromRGB(255, 180, 60))
                    end
                end
            end
            
            if State.ESP_Berries then
                for _, obj in ipairs(recursiveFind(isBerry, 3)) do
                    if not espObjects[obj] then
                        createESP(obj, Color3.fromRGB(180, 100, 255), BERRY_TYPES[obj.Name])
                    end
                end
            end
            
            if State.ESP_Chests then
                for _, obj in ipairs(getAllChests()) do
                    if not espObjects[obj] then
                        createESP(obj, Color3.fromRGB(255, 220, 60))
                    end
                end
            end
            
            if State.ESP_Islands then
                for _, isl in ipairs(ISLANDS) do
                    local key = tostring(isl.cf.Position)
                    if not espObjects[key] then
                        local part = Instance.new("Part")
                        part.Anchored = true
                        part.CanCollide = false
                        part.Transparency = 1
                        part.Size = Vector3.new(1,1,1)
                        part.CFrame = isl.cf
                        part.Parent = workspace
                        createESP(part, Color3.fromRGB(100, 200, 255))
                        espObjects[key] = espObjects[part]
                        espObjects[part].baseName = isl.name
                        espObjects[part].islandPart = part
                    end
                end
            end
        end
        
        -- Labels
        if now - lastLabel > 0.2 then
            lastLabel = now
            updateESPLabels()
        end
        
        -- AutoFarm
        if State.AutoFarm and now - lastFarm > Config.FarmDelay then
            lastFarm = now
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
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
                        local weapon = getWeapon()
                        if weapon then pcall(function() weapon:Activate() end) end
                        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(Config.FarmDelay * 0.3)
                        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    end
                end
            end
        end
        
        -- AutoChest
        if State.AutoChest and now - lastFarm > 3 then
            lastFarm = now
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local chests = getAllChests()
                local best, dist = nil, math.huge
                for _, c in ipairs(chests) do
                    local h = c:FindFirstChild("Handle") or c.PrimaryPart
                    if h then
                        local d = (h.Position - hrp.Position).Magnitude
                        if d < dist and d < 700 then best, dist = c, d end
                    end
                end
                if best then
                    local h = best:FindFirstChild("Handle") or best.PrimaryPart
                    flyTo(hrp, h.CFrame * CFrame.new(0, 0, 3))
                end
            end
        end
        
        -- AutoHaki
        if State.AutoHaki and p.Character then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Ken", true) end)
        end
        
        -- AutoClick
        if State.AutoClick then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- ===== AUTO QUEST FULL =====
task.spawn(function()
    while getgenv().GOSHA_RUNNING do
        task.wait(3)
        if State.AutoQuestFull then
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local sea = getCurrentSea()
                local lvl = 1
                pcall(function() lvl = p.Data.Level.Value end)
                local quests = QuestNPCs[sea] or {}
                local best = nil
                for _, q in ipairs(quests) do
                    if lvl >= q.lvl then best = q end
                end
                if best then
                    -- 1. Летим к NPC
                    flyTo(char.HumanoidRootPart, best.cf * CFrame.new(0, 0, 5), 1.5)
                    task.wait(0.5)
                    -- 2. Отправляем пакет на взятие квеста
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", best.quest, best.num)
                    end)
                    task.wait(0.5)
                    -- 3. Фармим 30 секунд
                    local endTime = tick() + 30
                    while tick() < endTime and State.AutoQuestFull and getgenv().GOSHA_RUNNING do
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
                                local weapon = getWeapon()
                                if weapon then pcall(function() weapon:Activate() end) end
                            end
                        end
                        task.wait(0.5)
                    end
                    -- 4. Сдаём
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("CompleteQuest")
                    end)
                end
            end
        end
    end
end)

-- Anti-AFK
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
    Title = "Gosha HUB v1.0",
    Text = "Загружено! 7 вкладок функций.",
    Duration = 5
})
warn("[Gosha HUB v1.0] Загружено успешно")
