--[[
    ╔══════════════════════════════════════════════╗
    ║           GOSHA HUB v3.0                     ║
    ║           Fix Follow + TP via Spawn          ║
    ║           by Gta90988                        ║
    ╚══════════════════════════════════════════════╝
]]

if getgenv().GOSHA_HUB then pcall(function() getgenv().GOSHA_HUB:Destroy() end) end
if getgenv().GOSHA_CLEANUP then pcall(getgenv().GOSHA_CLEANUP) end
getgenv().GOSHA_RUNNING = true

-- ===== RAYFIELD UI =====
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Gosha HUB",
    Icon = 0,
    LoadingTitle = "Gosha HUB",
    LoadingSubtitle = "by Gta90988",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GoshaHub",
        FileName = "Config"
    },
    KeySystem = false
})
getgenv().GOSHA_HUB = Window

-- ===== СЕРВИСЫ =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- ===== ОСТРОВА (с точками спавна) =====
local ISLANDS = {
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
    {name="Cafe", cf=CFrame.new(-380,15,260), sea=2},
    {name="Kingdom of Rose", cf=CFrame.new(-400,30,2000), sea=2},
    {name="Green Zone", cf=CFrame.new(100,20,500), sea=2},
    {name="Graveyard Island", cf=CFrame.new(-4000,30,-5000), sea=2},
    {name="Ice Castle", cf=CFrame.new(500,30,-1500), sea=2},
    {name="Snow Mountain", cf=CFrame.new(1000,50,-1000), sea=2},
    {name="Forgotten Island", cf=CFrame.new(-3000,20,-2000), sea=2},
    {name="Port Town", cf=CFrame.new(-300,20,5000), sea=3},
    {name="Hydra Island", cf=CFrame.new(5000,30,1000), sea=3},
    {name="Great Tree", cf=CFrame.new(2000,50,-2000), sea=3},
    {name="Floating Turtle", cf=CFrame.new(3000,30,3000), sea=3},
    {name="Tiki Outpost", cf=CFrame.new(-1000,20,-5000), sea=3},
    {name="Candy Cane Land", cf=CFrame.new(2000,30,3000), sea=3},
    {name="Prehistoric Island", cf=CFrame.new(5000,30,-4000), sea=3},
}

-- Точки спавна (используются для ТП к игроку через остров)
local SpawnPoints = {
    ["Starter Island"] = CFrame.new(0, 20, 0),
    ["Marine Fortress"] = CFrame.new(-2500, 30, -2500),
    ["Middle Town"] = CFrame.new(-600, 15, 600),
    ["Jungle"] = CFrame.new(-1500, 20, 200),
    ["Pirate Village"] = CFrame.new(-1200, 20, 3300),
    ["Desert"] = CFrame.new(-1300, 20, 4300),
    ["Frozen Village"] = CFrame.new(-1100, 20, 5800),
    ["Colosseum"] = CFrame.new(-1500, 40, 2000),
    ["Magma Village"] = CFrame.new(-5200, 30, 1000),
    ["Underwater City"] = CFrame.new(-4000, -200, 5000),
    ["Fountain City"] = CFrame.new(5200, 30, 4000),
    ["Skylands"] = CFrame.new(-4500, 800, -3000),
    ["Cafe"] = CFrame.new(-380, 15, 260),
    ["Kingdom of Rose"] = CFrame.new(-400, 30, 2000),
    ["Green Zone"] = CFrame.new(100, 20, 500),
    ["Graveyard Island"] = CFrame.new(-4000, 30, -5000),
    ["Ice Castle"] = CFrame.new(500, 30, -1500),
    ["Snow Mountain"] = CFrame.new(1000, 50, -1000),
    ["Forgotten Island"] = CFrame.new(-3000, 20, -2000),
    ["Port Town"] = CFrame.new(-300, 20, 5000),
    ["Hydra Island"] = CFrame.new(5000, 30, 1000),
    ["Great Tree"] = CFrame.new(2000, 50, -2000),
    ["Floating Turtle"] = CFrame.new(3000, 30, 3000),
    ["Tiki Outpost"] = CFrame.new(-1000, 20, -5000),
}

-- Определить ближайший остров к позиции
local function getIslandFromPosition(targetPos)
    local closest, minDist = nil, math.huge
    for name, cf in pairs(SpawnPoints) do
        local d = (targetPos - cf.Position).Magnitude
        if d < minDist then
            minDist = d
            closest = name
        end
    end
    return closest, minDist
end

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

-- ===== ВЫБОР ОРУЖИЯ =====
local function getWeapon()
    local char = p.Character
    if not char then return nil end
    local melee, sword, gun, fruit = nil, nil, nil, nil
    for _, w in ipairs(char:GetChildren()) do
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
    if Config.Weapon == "Auto" then
        return fruit or sword or melee or gun or char:FindFirstChildOfClass("Tool")
    end
    return char:FindFirstChildOfClass("Tool")
end

-- ===== STATE =====
local State = {
    AutoFarm = false, BringMobs = false, AutoHaki = false,
    AutoClick = false, AutoQuestFull = false, AutoChest = false,
    ESP_Mobs = false, ESP_Players = false, ESP_Fruits = false,
    ESP_Berries = false, ESP_Chests = false, ESP_Islands = false,
    Fly = false
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

-- ═══════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════

-- ===== FARM =====
local FarmTab = Window:CreateTab("Farm", "sword")

FarmTab:CreateSection("Автофарм")

FarmTab:CreateToggle({
    Name = "AutoFarm (плавный)",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v) State.AutoFarm = v end
})

FarmTab:CreateToggle({
    Name = "Bring Mobs",
    CurrentValue = false,
    Flag = "BringMobs",
    Callback = function(v) State.BringMobs = v end
})

FarmTab:CreateToggle({
    Name = "Auto Haki (Buso + Ken)",
    CurrentValue = false,
    Flag = "AutoHaki",
    Callback = function(v) State.AutoHaki = v end
})

FarmTab:CreateToggle({
    Name = "Auto Click",
    CurrentValue = false,
    Flag = "AutoClick",
    Callback = function(v) State.AutoClick = v end
})

FarmTab:CreateToggle({
    Name = "Auto Chest",
    CurrentValue = false,
    Flag = "AutoChest",
    Callback = function(v) State.AutoChest = v end
})

FarmTab:CreateDropdown({
    Name = "Оружие",
    Options = {"Auto", "Melee", "Sword", "Gun", "Fruit"},
    CurrentOption = {"Auto"},
    Flag = "Weapon",
    Callback = function(v) Config.Weapon = v[1] end
})

FarmTab:CreateSlider({
    Name = "Зона атаки",
    Range = {5, 200},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 50,
    Flag = "AttackRadius",
    Callback = function(v) Config.AttackRadius = v end
})

FarmTab:CreateSlider({
    Name = "Задержка атаки",
    Range = {1, 20},
    Increment = 1,
    Suffix = " x0.1с",
    CurrentValue = 5,
    Flag = "FarmDelay",
    Callback = function(v) Config.FarmDelay = v * 0.1 end
})

FarmTab:CreateSlider({
    Name = "Время полёта",
    Range = {5, 30},
    Increment = 1,
    Suffix = " x0.1с",
    CurrentValue = 15,
    Flag = "FlyTime",
    Callback = function(v) Config.FlyTime = v * 0.1 end
})

FarmTab:CreateButton({
    Name = "ТП к мобу (плавно)",
    Callback = function()
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
    end
})

FarmTab:CreateButton({
    Name = "ТП к сундуку",
    Callback = function()
        local chests = getAllChests()
        if #chests == 0 then
            Rayfield:Notify({Title="Сундуки", Content="Не найдено", Duration=3})
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
    end
})

-- ===== QUEST =====
local QuestTab = Window:CreateTab("Quest", "scroll")

QuestTab:CreateSection("Квесты")

QuestTab:CreateToggle({
    Name = "Auto Quest (полный цикл)",
    CurrentValue = false,
    Flag = "AutoQuestFull",
    Callback = function(v) State.AutoQuestFull = v end
})

QuestTab:CreateButton({
    Name = "Взять квест сейчас",
    Callback = function()
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
            Rayfield:Notify({Title="Квест взят", Content=best.name, Duration=3})
        end
    end
})

QuestTab:CreateButton({
    Name = "Сдать квест",
    Callback = function()
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("CompleteQuest") end)
        Rayfield:Notify({Title="Квест", Content="Сдан", Duration=3})
    end
})

-- ===== VISUAL =====
local VisualTab = Window:CreateTab("Visual", "eye")

VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "ESP Мобы",
    CurrentValue = false,
    Flag = "ESP_Mobs",
    Callback = function(v)
        State.ESP_Mobs = v
        if not v then for obj, _ in pairs(espObjects) do if isMob(obj) then destroyESP(obj) end end end
    end
})

VisualTab:CreateToggle({
    Name = "ESP Игроки (HP+LVL+FRUIT)",
    CurrentValue = false,
    Flag = "ESP_Players",
    Callback = function(v)
        State.ESP_Players = v
        if not v then for obj, _ in pairs(espObjects) do if Players:GetPlayerFromCharacter(obj) then destroyESP(obj) end end end
    end
})

VisualTab:CreateToggle({
    Name = "ESP Фрукты",
    CurrentValue = false,
    Flag = "ESP_Fruits",
    Callback = function(v)
        State.ESP_Fruits = v
        if not v then for obj, _ in pairs(espObjects) do if isFruit(obj) then destroyESP(obj) end end end
    end
})

VisualTab:CreateToggle({
    Name = "ESP Ягоды",
    CurrentValue = false,
    Flag = "ESP_Berries",
    Callback = function(v)
        State.ESP_Berries = v
        if not v then for obj, _ in pairs(espObjects) do if isBerry(obj) then destroyESP(obj) end end end
    end
})

VisualTab:CreateToggle({
    Name = "ESP Сундуки",
    CurrentValue = false,
    Flag = "ESP_Chests",
    Callback = function(v)
        State.ESP_Chests = v
        if not v then for obj, _ in pairs(espObjects) do if isChest(obj) then destroyESP(obj) end end end
    end
})

VisualTab:CreateButton({
    Name = "ВЫКЛЮЧИТЬ ВСЁ ESP",
    Callback = function()
        local count = getgenv().GOSHA_CLEANUP()
        State.ESP_Mobs = false
        State.ESP_Players = false
        State.ESP_Fruits = false
        State.ESP_Berries = false
        State.ESP_Chests = false
        State.ESP_Islands = false
        Rayfield:Notify({Title="ESP", Content="Очищено: " .. count, Duration=3})
    end
})

-- ===== ISLANDS =====
local IslandsTab = Window:CreateTab("Islands", "map")

IslandsTab:CreateSection("Телепорт по островам")

IslandsTab:CreateButton({
    Name = "Авто-определение моря",
    Callback = function() Config.CurrentSea = "Auto" end
})

for _, isl in ipairs(ISLANDS) do
    IslandsTab:CreateButton({
        Name = "[" .. isl.sea .. "] " .. isl.name,
        Callback = function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                flyTo(p.Character.HumanoidRootPart, isl.cf)
                Rayfield:Notify({Title="ТП", Content=isl.name, Duration=2})
            end
        end
    })
end

-- ===== PLAYERS =====
local PlayersTab = Window:CreateTab("Players", "users")

PlayersTab:CreateSection("Слежка и ТП к игрокам")

-- Динамический список игроков
local playerNames = {"None"}

local function refreshPlayerList()
    playerNames = {"None"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= p then
            table.insert(playerNames, plr.Name)
        end
    end
    return playerNames
end

-- Дропдаун со списком игроков
local playerDropdown = PlayersTab:CreateDropdown({
    Name = "Выбрать игрока",
    Options = refreshPlayerList(),
    CurrentOption = {"None"},
    Flag = "FollowPlayer",
    Callback = function(v)
        if v[1] == "None" then
            Config.FollowTarget = nil
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
            end
            Rayfield:Notify({Title="Слежка", Content="Отключено", Duration=2})
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == v[1] then
                    Config.FollowTarget = plr
                    Rayfield:Notify({Title="Слежка", Content="Следим за " .. plr.Name, Duration=3})
                end
            end
        end
    end
})

PlayersTab:CreateButton({
    Name = "Обновить список игроков",
    Callback = function()
        local names = refreshPlayerList()
        pcall(function()
            playerDropdown:Refresh(names, true)
        end)
        Rayfield:Notify({Title="Игроки", Content="Найдено: " .. (#names - 1), Duration=3})
    end
})

PlayersTab:CreateButton({
    Name = "Следить за игроком (вкл/выкл)",
    Callback = function()
        if Config.FollowTarget then
            Rayfield:Notify({Title="Слежка", Content="Следим за " .. Config.FollowTarget.Name, Duration=3})
        else
            Rayfield:Notify({Title="Слежка", Content="Выбери игрока в списке выше", Duration=3})
        end
    end
})

PlayersTab:CreateButton({
    Name = "ТП к игроку (через спавн острова)",
    Callback = function()
        if not Config.FollowTarget then
            Rayfield:Notify({Title="Ошибка", Content="Сначала выбери игрока", Duration=3})
            return
        end
        
        local targetPlayer = Config.FollowTarget
        local char = p.Character
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if not (targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")) then
            Rayfield:Notify({Title="Ошибка", Content="Цель не в игре или мертва", Duration=3})
            return
        end
        if not myHrp then
            Rayfield:Notify({Title="Ошибка", Content="Твой персонаж не загружен", Duration=3})
            return
        end

        local targetPos = targetPlayer.Character.HumanoidRootPart.Position
        local islandName, distance = getIslandFromPosition(targetPos)

        -- Этап 1: ТП на точку спавна острова
        if islandName and SpawnPoints[islandName] then
            Rayfield:Notify({
                Title="Этап 1/2",
                Content="Лечу на остров: " .. islandName,
                Duration=3
            })
            flyTo(myHrp, SpawnPoints[islandName], 2.5)
            task.wait(0.5)
        else
            Rayfield:Notify({Title="Ошибка", Content="Не удалось определить остров", Duration=3})
            return
        end

        -- Этап 2: Летим к игроку
        Rayfield:Notify({
            Title="Этап 2/2",
            Content="Лечу к " .. targetPlayer.Name,
            Duration=3
        })
        local currentHrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if currentHrp then
            flyTo(myHrp, safePosition(currentHrp.CFrame, 5), 2)
        end
    end
})

PlayersTab:CreateButton({
    Name = "Прекратить слежку",
    Callback = function()
        Config.FollowTarget = nil
        if p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then workspace.CurrentCamera.CameraSubject = hum end
        end
        Rayfield:Notify({Title="Слежка", Content="Остановлено", Duration=2})
    end
})

-- ===== MOVE =====
local MoveTab = Window:CreateTab("Move", "wind")

MoveTab:CreateSection("Движение")

MoveTab:CreateToggle({
    Name = "Fly (клавиша F)",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v) State.Fly = v end
})

MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        Config.WalkSpeed = v
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
})

-- ===== MISC =====
local MiscTab = Window:CreateTab("Misc", "settings")

MiscTab:CreateSection("Разное")

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v) getgenv().AntiAFK = v end
})

MiscTab:CreateButton({
    Name = "Показать FPS / Ping",
    Callback = function()
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        Rayfield:Notify({Title="Info", Content="FPS: " .. fps .. " | Ping: " .. ping .. "ms", Duration=5})
    end
})

MiscTab:CreateButton({
    Name = "Респавн",
    Callback = function()
        if p.Character then p.Character:BreakJoints() end
    end
})

-- ═══════════════════════════════════════════
-- ЛОГИКА
-- ═══════════════════════════════════════════

-- Fly
local flyVel, flyGyro
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

-- ИСПРАВЛЕННАЯ СЛЕЖКА (через Humanoid, а не модель)
task.spawn(function()
    while getgenv().GOSHA_RUNNING do
        task.wait(0.2)
        if Config.FollowTarget and Config.FollowTarget.Character then
            local targetChar = Config.FollowTarget.Character
            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
            if targetHum then
                workspace.CurrentCamera.CameraSubject = targetHum
            end
        end
    end
end)

-- Основной цикл
task.spawn(function()
    local lastESP, lastLabel, lastFarm = 0, 0, 0
    
    while getgenv().GOSHA_RUNNING do
        task.wait(0.1)
        local now = tick()
        
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
        end
        
        if now - lastLabel > 0.2 then
            lastLabel = now
            updateESPLabels()
        end
        
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
        
        if State.AutoHaki and p.Character then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Ken", true) end)
        end
        
        if State.AutoClick then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

-- Auto Quest
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
                    flyTo(char.HumanoidRootPart, best.cf * CFrame.new(0, 0, 5), 1.5)
                    task.wait(0.5)
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", best.quest, best.num)
                    end)
                    task.wait(0.5)
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

-- ===== ГОТОВО =====
Rayfield:Notify({
    Title = "Gosha HUB v3.0",
    Content = "Загружено! Слежка и ТП к игрокам исправлены.",
    Duration = 5
})
warn("[Gosha HUB v3.0] Загружено успешно")
