--[[
    ╔══════════════════════════════════════════════╗
    ║           GOSHA HUB v15.0                    ║
    ║   Key System | ESP Fix | Full Features       ║
    ╚══════════════════════════════════════════════╝
]]

if getgenv().GOSHA_HUB then pcall(function() getgenv().GOSHA_HUB:Destroy() end) end
if getgenv().GOSHA_CLEANUP then pcall(getgenv().GOSHA_CLEANUP) end

-- ============================================================
-- СИСТЕМА КЛЮЧЕЙ
-- ============================================================
local FOREVER_KEYS = {"GOSHAPERM1", "GOSHAPERM2"}

local function isValidKey(key)
    for _, k in ipairs(FOREVER_KEYS) do
        if k == key then return "forever" end
    end
    -- Ключи на час: GOSHA-1-1H ... GOSHA-10000-1H
    local num = key:match("^GOSHA%-(%d+)%-1H$")
    if num then
        local n = tonumber(num)
        if n and n >= 1 and n <= 10000 then
            return "hour"
        end
    end
    return false
end

-- Проверка сохранённого ключа
local savedKey = nil
pcall(function()
    if isfile and readfile and isfile("GoshaKey.txt") then
        savedKey = readfile("GoshaKey.txt")
    end
end)

local function getSavedTime()
    local t = nil
    pcall(function()
        if isfile and readfile and isfile("GoshaKeyTime.txt") then
            t = tonumber(readfile("GoshaKeyTime.txt"))
        end
    end)
    return t
end

local function saveKey(key, time)
    pcall(function()
        if writefile then
            writefile("GoshaKey.txt", key)
            if time then writefile("GoshaKeyTime.txt", tostring(time)) end
        end
    end)
end

local function checkSavedKey()
    if not savedKey then return false end
    local keyType = isValidKey(savedKey)
    if not keyType then return false end
    if keyType == "forever" then return true end
    -- Ключ на час: проверяем время
    if keyType == "hour" then
        local t = getSavedTime()
        if t and (os.time() - t) < 3600 then
            return true
        end
    end
    return false
end

-- ============================================================
-- ЗАГРУЗКА СКРИПТА (если ключ валиден) ИЛИ ПОКАЗ ОКНА ВВОДА
-- ============================================================
local function StartScript()
    -- ===== RAYFIELD UI =====
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = Rayfield:CreateWindow({
        Name = "Gosha HUB",
        Icon = 0,
        LoadingTitle = "Gosha HUB v15",
        LoadingSubtitle = "by Gta90988",
        Theme = "Green",
        ToggleUIKeybind = "K",
        ConfigurationSaving = { Enabled = true, FolderName = "GoshaHub", FileName = "Config" },
        KeySystem = false
    })
    getgenv().GOSHA_HUB = Window
    getgenv().GOSHA_RUNNING = true

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
        FlyTime = 1.5, AttackRadius = 50, FarmDelay = 0.5,
        AutoDetect = true, WalkSpeed = 16, CurrentSea = "Auto",
        Weapon = "Auto", FollowTarget = nil, AirFarmHeight = 12,
        SafeTP = true, TargetMob = "Auto", ESPDistance = 3000, TP_Speed = 100
    }

    local function randFloat(a, b) return a + math.random() * (b - a) end
    local function safePosition(cf, dist)
        local a = math.rad(math.random(0, 360))
        return cf * CFrame.new(math.cos(a) * dist, 0, math.sin(a) * dist)
    end

    local function flyTo(hrp, target, duration)
        duration = duration or Config.FlyTime
        if Config.AutoDetect then duration = duration * randFloat(0.9, 1.3) end
        local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = target})
        tween:Play()
        tween.Completed:Wait()
        task.wait(randFloat(0.05, 0.15))
    end

    local function safeTP(hrp, targetCF)
        if not Config.SafeTP then hrp.CFrame = targetCF + Vector3.new(0, 5, 0) return end
        local safeTarget = targetCF + Vector3.new(0, 15, 0)
        flyTo(hrp, CFrame.new(hrp.Position.X, hrp.Position.Y + 120, hrp.Position.Z), 0.8)
        task.wait(0.2)
        flyTo(hrp, CFrame.new(safeTarget.Position.X, safeTarget.Position.Y + 120, safeTarget.Position.Z), 1.5)
        task.wait(0.2)
        flyTo(hrp, safeTarget, 0.6)
    end

    local function recursiveFind(predicate, maxDepth)
        maxDepth = maxDepth or 6
        local found = {}
        local function scan(parent, depth)
            if depth > maxDepth then return end
            for _, obj in ipairs(parent:GetChildren()) do
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

    -- ===== БОССЫ =====
    local BOSS_LIST = {"Gorilla King","Bobby","Yeti","Smoke Admiral","Axe Hand","Warden","Magma Admiral","Fishman Lord","Diamond","Jeremy","Fajita","Cursed Captain","Greybeard","Sea King","Cake Prince","Don Swan","Kitsune","Dough King","Rip Indra","Order","Longma","Soul Reaper"}
    local function isBoss(obj)
        for _, b in ipairs(BOSS_LIST) do
            if obj.Name == b and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then return true end
        end
        return false
    end
    local function getAllBosses() return recursiveFind(isBoss, 3) end

    -- ===== СУНДУКИ =====
    local function isChest(obj)
        local n = obj.Name:lower()
        return (n:find("chest") or n:find("treasure") or n:find("crate"))
            and (obj:IsA("Model") or obj:IsA("BasePart"))
            and (obj:FindFirstChild("Handle") or obj.PrimaryPart)
    end
    local function getAllChests() return recursiveFind(isChest, 5) end

    -- ===== ФРУКТЫ =====
    local FRUITS = {["Rocket"]=true,["Spin"]=true,["Chop"]=true,["Spring"]=true,["Bomb"]=true,["Smoke"]=true,["Spike"]=true,["Flame"]=true,["Falcon"]=true,["Ice"]=true,["Sand"]=true,["Dark"]=true,["Diamond"]=true,["Light"]=true,["Rubber"]=true,["Barrier"]=true,["Magma"]=true,["Door"]=true,["Quake"]=true,["Buddha"]=true,["Love"]=true,["Spider"]=true,["Sound"]=true,["Phoenix"]=true,["Portal"]=true,["Rumble"]=true,["Pain"]=true,["Blizzard"]=true,["Gravity"]=true,["Mammoth"]=true,["T-Rex"]=true,["Dough"]=true,["Shadow"]=true,["Venom"]=true,["Control"]=true,["Spirit"]=true,["Dragon"]=true,["Leopard"]=true,["Kitsune"]=true}
    local function isFruit(obj)
        if not obj or not obj.Parent then return false end
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then return true end
        if obj:IsA("Model") then
            if not obj:FindFirstChild("Handle") and not obj.PrimaryPart then return false end
            for name, _ in pairs(FRUITS) do if obj.Name == name or obj.Name:find(name) then return true end end
        end
        return false
    end
    local function getFruitName(obj) for name, _ in pairs(FRUITS) do if obj.Name == name or obj.Name:find(name) then return name end end return obj.Name end
    local function getAllFruits()
        local list = {}
        for _, obj in ipairs(workspace:GetChildren()) do if isFruit(obj) then table.insert(list, obj) end end
        for _, obj in ipairs(recursiveFind(isFruit, 4)) do table.insert(list, obj) end
        return list
    end

    -- ===== ЯГОДЫ =====
    local BERRY_TYPES = {["Green Toad Berry"]="Green Toad",["White Cloud Berry"]="White Cloud",["Blue Icicle Berry"]="Blue Icicle",["Purple Jelly Berry"]="Purple Jelly",["Pink Pig Berry"]="Pink Pig",["Orange Berry"]="Orange",["Yellow Star Berry"]="Yellow Star",["Red Cherry Berry"]="Red Cherry"}
    local function isBerry(obj)
        if not obj or not obj.Parent then return false end
        if not (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool")) then return false end
        local n = obj.Name:lower()
        if n:find("berry") then return true end
        for berryName, _ in pairs(BERRY_TYPES) do if obj.Name == berryName or obj.Name:find(berryName) then return true end end
        return false
    end
    local function getAllBerries() return recursiveFind(isBerry, 5) end

    -- ===== ИГРОКИ =====
    local function getPlayerCharacter(plr)
        if plr == p then return nil end
        local char = plr.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return nil end
        return char
    end

    -- ===== ОСТРОВА =====
    local ISLANDS = {
        {name="Starter Island", cf=CFrame.new(0,20,0), sea=1}, {name="Marine Fortress", cf=CFrame.new(-2500,30,-2500), sea=1}, {name="Middle Town", cf=CFrame.new(-600,15,600), sea=1}, {name="Jungle", cf=CFrame.new(-1500,20,200), sea=1}, {name="Pirate Village", cf=CFrame.new(-1200,20,3300), sea=1}, {name="Desert", cf=CFrame.new(-1300,20,4300), sea=1}, {name="Frozen Village", cf=CFrame.new(-1100,20,5800), sea=1}, {name="Colosseum", cf=CFrame.new(-1500,40,2000), sea=1}, {name="Magma Village", cf=CFrame.new(-5200,30,1000), sea=1}, {name="Underwater City", cf=CFrame.new(-4000,-200,5000), sea=1}, {name="Fountain City", cf=CFrame.new(5200,30,4000), sea=1}, {name="Skylands", cf=CFrame.new(-4500,800,-3000), sea=1},
        {name="Cafe", cf=CFrame.new(-380, 60, 260), sea=2},
        {name="Kingdom of Rose", cf=CFrame.new(-400, 35, 2000), sea=2},
        {name="Green Zone", cf=CFrame.new(100,20,500), sea=2}, {name="Graveyard Island", cf=CFrame.new(-4000,30,-5000), sea=2}, {name="Ice Castle", cf=CFrame.new(500,30,-1500), sea=2}, {name="Snow Mountain", cf=CFrame.new(1000,50,-1000), sea=2}, {name="Forgotten Island", cf=CFrame.new(-3000,20,-2000), sea=2},
        {name="Port Town", cf=CFrame.new(-300,20,5000), sea=3}, {name="Hydra Island", cf=CFrame.new(5000,30,1000), sea=3}, {name="Great Tree", cf=CFrame.new(2000,50,-2000), sea=3}, {name="Floating Turtle", cf=CFrame.new(3000,30,3000), sea=3}, {name="Tiki Outpost", cf=CFrame.new(-1000,20,-5000), sea=3}, {name="Candy Cane Land", cf=CFrame.new(2000,30,3000), sea=3}, {name="Prehistoric Island", cf=CFrame.new(5000,30,-4000), sea=3}
    }

    local function getCurrentSea()
        if Config.CurrentSea ~= "Auto" then return Config.CurrentSea end
        local char = p.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return 1 end
        local pos = char.HumanoidRootPart.Position
        if pos.Z > 4000 or pos.X > 4000 then return 3
        elseif pos.Z > -1000 and pos.Z < 3000 and pos.X > -1000 and pos.X < 1500 then return 2
        else return 1 end
    end

    local function getPlayerInfo(plr)
        local hp, maxHp = 0, 100
        local lvl, fruit = "?", "None"
        if plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h then hp, maxHp = math.floor(h.Health), math.floor(h.MaxHealth) end
        end
        local ls = plr:FindFirstChild("leaderstats")
        if ls then local l = ls:FindFirstChild("Level"); if l then lvl = l.Value end end
        pcall(function() fruit = plr.Data.Fruit.Value end)
        return hp, maxHp, lvl, fruit
    end

    local function getWeapon()
        local char = p.Character
        if not char then return nil end
        local melee, sword, gun, fruit
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
        if Config.Weapon == "Auto" then return fruit or sword or melee or gun or char:FindFirstChildOfClass("Tool") end
        return char:FindFirstChildOfClass("Tool")
    end

    -- ===== STATE =====
    local State = {
        AutoFarm = false, AutoFarmAir = false, AutoBoss = false,
        AutoHaki = false, AutoClick = false, AutoChest = false,
        AutoBerryFarm = false,
        ESP_Mobs = false, ESP_Players = false, ESP_Fruits = false,
        ESP_Berries = false, ESP_Chests = false, ESP_Bosses = false,
        Fly = false, AutoStore = false,
        WaterWalk = false, NoClip = false, InfiniteJump = false, AutoDash = false
    }

    -- ===== ESP (ИСПРАВЛЕННЫЙ) =====
    getgenv().GOSHA_ESP = {}
    local espCache = getgenv().GOSHA_ESP

    local function removeESP(obj)
        if espCache[obj] then
            pcall(function() if espCache[obj].hl then espCache[obj].hl:Destroy() end end)
            pcall(function() if espCache[obj].bb then espCache[obj].bb:Destroy() end end)
            espCache[obj] = nil
        end
    end

    getgenv().GOSHA_CLEANUP = function()
        local count = 0
        for obj, _ in pairs(espCache) do removeESP(obj); count = count + 1 end
        return count
    end

    local function applyESP(obj, color, text)
        if not obj or not obj.Parent then return end
        local myChar = p.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle") or obj.PrimaryPart
        -- ФИКС: если root нет — пробуем взять любую BasePart
        if not root and obj:IsA("Model") then
            root = obj:FindFirstChildWhichIsA("BasePart")
        end
        if not root then return end

        local dist = (root.Position - hrp.Position).Magnitude
        if dist > Config.ESPDistance then
            if espCache[obj] then removeESP(obj) end
            return
        end

        -- ФИКС: если Highlight уничтожен — пересоздаём
        if espCache[obj] and (not espCache[obj].hl or not espCache[obj].hl.Parent) then
            removeESP(obj)
        end

        if not espCache[obj] then
            pcall(function()
                local hl = Instance.new("Highlight")
                hl.FillColor = color
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = obj

                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 220, 0, 30)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.AlwaysOnTop = true
                bb.Parent = root

                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = color
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 13
                espCache[obj] = {hl = hl, bb = bb, lbl = lbl, baseName = text or obj.Name}
            end)
        end

        local data = espCache[obj]
        if data and data.lbl then
            data.lbl.Text = data.baseName .. " [" .. math.floor(dist) .. "m]"
        end
    end

    -- ===== UI =====
    local FarmTab = Window:CreateTab("Farm", "sword")
    FarmTab:CreateSection("Автофарм")
    FarmTab:CreateToggle({ Name = "Auto Farm (Ground)", CurrentValue = false, Flag = "AutoFarm", Callback = function(v) State.AutoFarm = v end })
    FarmTab:CreateToggle({ Name = "Auto Farm (Air)", CurrentValue = false, Flag = "AutoFarmAir", Callback = function(v) State.AutoFarmAir = v end })
    FarmTab:CreateToggle({ Name = "Auto Haki", CurrentValue = false, Flag = "AutoHaki", Callback = function(v) State.AutoHaki = v end })
    FarmTab:CreateToggle({ Name = "Auto Click", CurrentValue = false, Flag = "AutoClick", Callback = function(v) State.AutoClick = v end })
    FarmTab:CreateToggle({ Name = "Auto Chest", CurrentValue = false, Flag = "AutoChest", Callback = function(v) State.AutoChest = v end })
    FarmTab:CreateToggle({ Name = "Auto Berry Farm", CurrentValue = false, Flag = "AutoBerryFarm", Callback = function(v) State.AutoBerryFarm = v end })
    FarmTab:CreateToggle({ Name = "Auto Boss", CurrentValue = false, Flag = "AutoBoss", Callback = function(v) State.AutoBoss = v end })
    FarmTab:CreateToggle({ Name = "Auto Store Fruit", CurrentValue = false, Flag = "AutoStore", Callback = function(v) State.AutoStore = v end })
    FarmTab:CreateDropdown({ Name = "Кого фармить", Options = {"Auto","Bandit","Monkey","Pirate","Brute","Snow Bandit","Zombie","Swan Pirate","Ice Pirate","Fishman","Soldier","Mercenary","Raider","Magma Ninja","Lava Pirate"}, CurrentOption = {"Auto"}, Flag = "TargetMob", Callback = function(v) Config.TargetMob = v[1] end })
    FarmTab:CreateDropdown({ Name = "Оружие", Options = {"Auto","Melee","Sword","Gun","Fruit"}, CurrentOption = {"Auto"}, Flag = "Weapon", Callback = function(v) Config.Weapon = v[1] end })
    FarmTab:CreateSlider({ Name = "Зона атаки", Range = {5,200}, Increment = 5, Suffix = " studs", CurrentValue = 50, Flag = "AttackRadius", Callback = function(v) Config.AttackRadius = v end })
    FarmTab:CreateSlider({ Name = "Задержка атаки", Range = {1,20}, Increment = 1, Suffix = " x0.1с", CurrentValue = 5, Flag = "FarmDelay", Callback = function(v) Config.FarmDelay = v * 0.1 end })
    FarmTab:CreateSlider({ Name = "Высота Air Farm", Range = {5,30}, Increment = 1, Suffix = " studs", CurrentValue = 12, Flag = "AirHeight", Callback = function(v) Config.AirFarmHeight = v end })

    local VisualTab = Window:CreateTab("Visual", "eye")
    VisualTab:CreateSection("ESP")
    VisualTab:CreateSlider({ Name = "Дальность ESP", Range = {500, 5000}, Increment = 100, Suffix = " studs", CurrentValue = 3000, Flag = "ESPDistance", Callback = function(v) Config.ESPDistance = v end })
    VisualTab:CreateToggle({ Name = "ESP Мобы", CurrentValue = false, Flag = "ESP_Mobs", Callback = function(v) State.ESP_Mobs = v; if not v then for o in pairs(espCache) do if isMob(o) then removeESP(o) end end end end })
    VisualTab:CreateToggle({ Name = "ESP Игроки", CurrentValue = false, Flag = "ESP_Players", Callback = function(v) State.ESP_Players = v; if not v then for o in pairs(espCache) do if Players:GetPlayerFromCharacter(o) then removeESP(o) end end end end })
    VisualTab:CreateToggle({ Name = "ESP Фрукты", CurrentValue = false, Flag = "ESP_Fruits", Callback = function(v) State.ESP_Fruits = v; if not v then for o in pairs(espCache) do if isFruit(o) then removeESP(o) end end end end })
    VisualTab:CreateToggle({ Name = "ESP Ягоды", CurrentValue = false, Flag = "ESP_Berries", Callback = function(v) State.ESP_Berries = v; if not v then for o in pairs(espCache) do if isBerry(o) then removeESP(o) end end end end })
    VisualTab:CreateToggle({ Name = "ESP Сундуки", CurrentValue = false, Flag = "ESP_Chests", Callback = function(v) State.ESP_Chests = v; if not v then for o in pairs(espCache) do if isChest(o) then removeESP(o) end end end end })
    VisualTab:CreateToggle({ Name = "ESP Боссы", CurrentValue = false, Flag = "ESP_Bosses", Callback = function(v) State.ESP_Bosses = v; if not v then for o in pairs(espCache) do if isBoss(o) then removeESP(o) end end end end })
    VisualTab:CreateButton({ Name = "ВЫКЛЮЧИТЬ ВСЁ ESP", Callback = function()
        local count = getgenv().GOSHA_CLEANUP()
        State.ESP_Mobs=false; State.ESP_Players=false; State.ESP_Fruits=false; State.ESP_Berries=false; State.ESP_Chests=false; State.ESP_Bosses=false
        Rayfield:Notify({Title="ESP", Content="Очищено: " .. count, Duration=3})
    end })

    local TeleportTab = Window:CreateTab("Teleport", "map")
    TeleportTab:CreateSection("К объектам")
    TeleportTab:CreateButton({ Name = "TP к ближайшему фрукту", Callback = function()
        local fruits = getAllFruits()
        if #fruits == 0 then Rayfield:Notify({Title="Фрукты", Content="Не найдено", Duration=3}) return end
        local char = p.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local best, dist = nil, math.huge
        for _, f in ipairs(fruits) do
            local h = f:FindFirstChild("Handle") or f.PrimaryPart
            if h then
                local d = (h.Position - hrp.Position).Magnitude
                if d < dist then best, dist = f, d end
            end
        end
        if best then
            local h = best:FindFirstChild("Handle") or best.PrimaryPart
            safeTP(hrp, h.CFrame * CFrame.new(0, 0, 3))
            Rayfield:Notify({Title="ТП к фрукту", Content=getFruitName(best) .. " [" .. math.floor(dist) .. "m]", Duration=3})
        end
    end })
    TeleportTab:CreateButton({ Name = "TP к ближайшей ягоде", Callback = function()
        local berries = getAllBerries()
        if #berries == 0 then Rayfield:Notify({Title="Ягоды", Content="Не найдено", Duration=3}) return end
        local char = p.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local best, dist = nil, math.huge
        for _, b in ipairs(berries) do
            local h = b:FindFirstChild("Handle") or b.PrimaryPart
            if h then
                local d = (h.Position - hrp.Position).Magnitude
                if d < dist then best, dist = b, d end
            end
        end
        if best then
            local h = best:FindFirstChild("Handle") or best.PrimaryPart
            safeTP(hrp, h.CFrame * CFrame.new(0, 0, 3))
            Rayfield:Notify({Title="ТП к ягоде", Content=best.Name .. " [" .. math.floor(dist) .. "m]", Duration=3})
        end
    end })
    TeleportTab:CreateButton({ Name = "TP к ближайшему сундуку", Callback = function()
        local chests = getAllChests()
        if #chests == 0 then Rayfield:Notify({Title="Сундуки", Content="Не найдено", Duration=3}) return end
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
            safeTP(hrp, h.CFrame * CFrame.new(0, 0, 3))
            Rayfield:Notify({Title="ТП к сундуку", Content=best.Name .. " [" .. math.floor(dist) .. "m]", Duration=3})
        end
    end })
    TeleportTab:CreateSection("Острова")
    TeleportTab:CreateToggle({ Name = "Safe TP", CurrentValue = true, Flag = "SafeTP", Callback = function(v) Config.SafeTP = v end })
    TeleportTab:CreateButton({ Name = "Авто-определение моря", Callback = function() Config.CurrentSea = "Auto" end })
    TeleportTab:CreateButton({ Name = "1 море", Callback = function() Config.CurrentSea = 1 end })
    TeleportTab:CreateButton({ Name = "2 море", Callback = function() Config.CurrentSea = 2 end })
    TeleportTab:CreateButton({ Name = "3 море", Callback = function() Config.CurrentSea = 3 end })
    for _, isl in ipairs(ISLANDS) do
        TeleportTab:CreateButton({ Name = "[" .. isl.sea .. "] " .. isl.name, Callback = function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                safeTP(p.Character.HumanoidRootPart, isl.cf * CFrame.new(0, 0, 5))
                Rayfield:Notify({Title="ТП", Content=isl.name, Duration=2})
            end
        end })
    end

    local PlayersTab = Window:CreateTab("Players", "users")
    PlayersTab:CreateSection("Слежка")
    local function getPlayerNames()
        local list = {"None"}
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= p then table.insert(list, plr.Name) end end
        return list
    end
    PlayersTab:CreateDropdown({
        Name = "Выбрать игрока", Options = getPlayerNames(), CurrentOption = {"None"}, Flag = "FollowPlayer",
        Callback = function(v)
            if v[1] == "None" then
                Config.FollowTarget = nil
                if p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then workspace.CurrentCamera.CameraSubject = hum end end
            else
                for _, plr in ipairs(Players:GetPlayers()) do if plr.Name == v[1] then Config.FollowTarget = plr end end
            end
        end
    })
    PlayersTab:CreateButton({ Name = "ТП к игроку", Callback = function()
        if not Config.FollowTarget then return end
        local tp = Config.FollowTarget
        local char = p.Character
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")) or not myHrp then return end
        local tPos = tp.Character.HumanoidRootPart.Position
        local closest, minD = nil, math.huge
        for _, isl in ipairs(ISLANDS) do
            local d = (tPos - isl.cf.Position).Magnitude
            if d < minD then minD = d; closest = isl end
        end
        if closest then safeTP(myHrp, closest.cf) end
        task.wait(0.5)
        local curHrp = tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
        if curHrp then safeTP(myHrp, safePosition(curHrp.CFrame, 5)) end
    end })
    PlayersTab:CreateButton({ Name = "Прекратить слежку", Callback = function()
        Config.FollowTarget = nil
        if p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); if hum then workspace.CurrentCamera.CameraSubject = hum end end
    end })

    local MoveTab = Window:CreateTab("Move", "wind")
    MoveTab:CreateSection("Движение")
    MoveTab:CreateToggle({ Name = "Fly (F)", CurrentValue = false, Flag = "Fly", Callback = function(v) State.Fly = v end })
    MoveTab:CreateSlider({ Name = "WalkSpeed", Range = {16,200}, Increment = 1, Suffix = " studs/s", CurrentValue = 16, Flag = "WalkSpeed", Callback = function(v)
        Config.WalkSpeed = v
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end })
    MoveTab:CreateSection("Хаки движения")
    MoveTab:CreateToggle({ Name = "Water Walk", CurrentValue = false, Flag = "WaterWalk", Callback = function(v) State.WaterWalk = v end })
    MoveTab:CreateToggle({ Name = "NoClip", CurrentValue = false, Flag = "NoClip", Callback = function(v) State.NoClip = v end })
    MoveTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "InfiniteJump", Callback = function(v) State.InfiniteJump = v end })
    MoveTab:CreateToggle({ Name = "Auto Dash", CurrentValue = false, Flag = "AutoDash", Callback = function(v) State.AutoDash = v end })

    local MiscTab = Window:CreateTab("Misc", "settings")
    MiscTab:CreateSection("Разное")
    MiscTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK", Callback = function(v) getgenv().AntiAFK = v end })
    MiscTab:CreateButton({ Name = "Респавн", Callback = function() if p.Character then p.Character:BreakJoints() end end })
    MiscTab:CreateButton({ Name = "FPS / Ping", Callback = function()
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        Rayfield:Notify({Title="Info", Content="FPS: " .. fps .. " | Ping: " .. ping .. "ms", Duration=5})
    end})

    local HelpTab = Window:CreateTab("Help", "circle-help")
    HelpTab:CreateSection("Поддержка")
    HelpTab:CreateButton({
        Name = "🔴 Discord сервер скрипта",
        Callback = function()
            setclipboard("https://discord.gg/trxhSYeJa")
            Rayfield:Notify({Title = "Gosha HUB | Discord", Content = "Ссылка скопирована!", Duration = 5})
        end
    })

    -- ===== ЛОГИКА =====
    local flyVel, flyGyro
    UserInput.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F and State.Fly then
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if flyVel then flyVel:Destroy(); flyGyro:Destroy(); flyVel, flyGyro = nil, nil
            else
                flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyVel.Parent = hrp
                flyGyro = Instance.new("BodyGyro"); flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyGyro.P = 1000; flyGyro.Parent = hrp
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

    local waterWalkBP
    RunService.Heartbeat:Connect(function()
        if State.WaterWalk and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < 5 then
                if not waterWalkBP then
                    waterWalkBP = Instance.new("BodyPosition")
                    waterWalkBP.MaxForce = Vector3.new(0, 40000, 0)
                    waterWalkBP.P = 5000
                    waterWalkBP.Position = Vector3.new(hrp.Position.X, 3, hrp.Position.Z)
                    waterWalkBP.Parent = hrp
                else
                    waterWalkBP.Position = Vector3.new(hrp.Position.X, 3, hrp.Position.Z)
                end
            else
                if waterWalkBP then waterWalkBP:Destroy(); waterWalkBP = nil end
            end
        else
            if waterWalkBP then waterWalkBP:Destroy(); waterWalkBP = nil end
        end
    end)

    RunService.Stepped:Connect(function()
        if State.NoClip and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
    end)

    UserInput.JumpRequest:Connect(function()
        if State.InfiniteJump and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    task.spawn(function()
        while getgenv().GOSHA_RUNNING do
            task.wait(3)
            if State.AutoDash and p.Character then
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Dash") end)
            end
        end
    end)

    task.spawn(function()
        while getgenv().GOSHA_RUNNING do
            task.wait(0.2)
            if Config.FollowTarget and Config.FollowTarget.Character then
                local hum = Config.FollowTarget.Character:FindFirstChildOfClass("Humanoid")
                if hum then workspace.CurrentCamera.CameraSubject = hum end
            end
        end
    end)

    p.CharacterAdded:Connect(function(char)
        task.wait(2)
        for obj, _ in pairs(espCache) do removeESP(obj) end
    end)

    -- ============= ОСНОВНОЙ ЦИКЛ =============
    task.spawn(function()
        local lastESP, lastFarm, lastChest, lastBerry, lastStore = 0, 0, 0, 0, 0
        while getgenv().GOSHA_RUNNING do
            task.wait(0.15)
            local now = tick()
            
            if now - lastESP > 0.5 then
                lastESP = now
                if State.ESP_Mobs then for _, m in ipairs(getAllMobs()) do applyESP(m, Color3.fromRGB(255, 60, 60)) end end
                if State.ESP_Players then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        local char = getPlayerCharacter(plr)
                        if char then
                            local hp, maxHp, lvl, fruit = getPlayerInfo(plr)
                            applyESP(char, Color3.fromRGB(60, 220, 60), plr.Name .. " HP:" .. hp .. " Lv:" .. lvl .. " " .. fruit)
                        end
                    end
                end
                if State.ESP_Fruits then for _, obj in ipairs(getAllFruits()) do applyESP(obj, Color3.fromRGB(255, 180, 60)) end end
                if State.ESP_Berries then for _, obj in ipairs(getAllBerries()) do applyESP(obj, Color3.fromRGB(180, 100, 255)) end end
                if State.ESP_Chests then for _, obj in ipairs(getAllChests()) do applyESP(obj, Color3.fromRGB(255, 220, 60)) end end
                if State.ESP_Bosses then for _, obj in ipairs(getAllBosses()) do applyESP(obj, Color3.fromRGB(255, 0, 150)) end end
                for obj, _ in pairs(espCache) do if not obj.Parent then removeESP(obj) end end
            end
            
            if (State.AutoFarm or State.AutoFarmAir) and now - lastFarm > Config.FarmDelay then
                lastFarm = now
                local char = p.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    local mobs = getAllMobs()
                    local best, dist = nil, math.huge
                    for _, m in ipairs(mobs) do
                        local match = Config.TargetMob == "Auto" or m.Name:lower():find(Config.TargetMob:lower())
                        if match then
                            local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d < dist then best, dist = m, d end
                        end
                    end
                    if best then
                        local targetCF = State.AutoFarmAir and (best.HumanoidRootPart.CFrame * CFrame.new(0, Config.AirFarmHeight, 3)) or safePosition(best.HumanoidRootPart.CFrame, 3)
                        flyTo(hrp, targetCF, 0.5)
                        local weapon = getWeapon(); if weapon then pcall(function() weapon:Activate() end) end
                        if State.AutoFarmAir then pcall(function() firetouchinterest(hrp, best.HumanoidRootPart, 0); task.wait(); firetouchinterest(hrp, best.HumanoidRootPart, 1) end) end
                        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(Config.FarmDelay * 0.3); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    end
                end
            end
            
            if State.AutoBerryFarm and now - lastBerry > 2 then
                lastBerry = now
                local char = p.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    local berries = getAllBerries()
                    local best, dist = nil, math.huge
                    for _, b in ipairs(berries) do
                        local h = b:FindFirstChild("Handle") or b.PrimaryPart
                        if h then
                            local d = (h.Position - hrp.Position).Magnitude
                            if d < dist and d < 500 then best, dist = b, d end
                        end
                    end
                    if best then
                        local h = best:FindFirstChild("Handle") or best.PrimaryPart
                        flyTo(hrp, h.CFrame * CFrame.new(0, 0, 3), 0.4)
                    end
                end
            end
            
            if State.AutoChest and now - lastChest > 2 then
                lastChest = now
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
                        flyTo(hrp, h.CFrame * CFrame.new(0, 0, 3), 0.4)
                    end
                end
            end
            
            if State.AutoBoss and now - lastFarm > Config.FarmDelay then
                lastFarm = now
                local char = p.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local bosses = getAllBosses()
                    local hrp = char.HumanoidRootPart
                    local best, dist = nil, math.huge
                    for _, b in ipairs(bosses) do local d = (b.HumanoidRootPart.Position - hrp.Position).Magnitude; if d < dist then best, dist = b, d end end
                    if best then
                        safeTP(hrp, safePosition(best.HumanoidRootPart.CFrame, 5))
                        local weapon = getWeapon(); if weapon then pcall(function() weapon:Activate() end) end
                        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(Config.FarmDelay * 0.3); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    end
                end
            end
            
            if State.AutoStore and now - lastStore > 5 then
                lastStore = now
                pcall(function()
                    local inv = ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
                    if inv then
                        for name, data in pairs(inv) do
                            if data.Type == "Blox Fruit" and data.Value <= 999999 then
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", name)
                            end
                        end
                    end
                end)
            end
            
            if State.AutoHaki and p.Character then
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Ken", true) end)
            end
            
            if State.AutoClick then VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1) end
        end
    end)

    p.Idled:Connect(function()
        if getgenv().AntiAFK ~= false then VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1); VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1) end
    end)

    p.CharacterAdded:Connect(function(char)
        task.wait(1)
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.WalkSpeed end
    end)

    Rayfield:Notify({ Title = "Gosha HUB v15.0", Content = "Загружено! ESP Fix + Key System", Duration = 5 })
    warn("[Gosha HUB v15.0] Загружено успешно")
end

-- ============================================================
-- ТОЧКА ВХОДА
-- ============================================================
if checkSavedKey() then
    -- Ключ уже сохранён и валиден — запускаем
    StartScript()
else
    -- Показываем окно ввода ключа
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KeySystemUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
    MainFrame.Size = UDim2.new(0, 350, 0, 250)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 15, 20))
    }
    UIGradient.Rotation = 45
    UIGradient.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
    Title.BorderSizePixel = 0
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "🔑 GOSHA HUB | KEY SYSTEM"
    Title.TextColor3 = Color3.fromRGB(100, 220, 150)
    Title.TextSize = 16
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = Title

    local Info = Instance.new("TextLabel")
    Info.Parent = MainFrame
    Info.BackgroundTransparency = 1
    Info.Position = UDim2.new(0, 10, 0, 50)
    Info.Size = UDim2.new(1, -20, 0, 30)
    Info.Font = Enum.Font.Gotham
    Info.Text = "Введите ключ для доступа к скрипту"
    Info.TextColor3 = Color3.fromRGB(180, 180, 180)
    Info.TextSize = 13

    local KeyInput = Instance.new("TextBox")
    KeyInput.Parent = MainFrame
    KeyInput.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
    KeyInput.BorderSizePixel = 0
    KeyInput.Position = UDim2.new(0.5, -140, 0, 90)
    KeyInput.Size = UDim2.new(0, 280, 0, 35)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.PlaceholderText = "GOSHA-1-1H или GOSHAPERM1"
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 14
    KeyInput.ClearTextOnFocus = false
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = KeyInput

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Parent = MainFrame
    SubmitButton.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Position = UDim2.new(0.5, -80, 0, 140)
    SubmitButton.Size = UDim2.new(0, 160, 0, 35)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Text = "✅ ПОДТВЕРДИТЬ"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 14
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = SubmitButton

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 10, 0, 185)
    StatusLabel.Size = UDim2.new(1, -20, 0, 25)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    StatusLabel.TextSize = 12

    local GetKeyButton = Instance.new("TextButton")
    GetKeyButton.Parent = MainFrame
    GetKeyButton.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
    GetKeyButton.BorderSizePixel = 0
    GetKeyButton.Position = UDim2.new(0.5, -80, 0, 215)
    GetKeyButton.Size = UDim2.new(0, 160, 0, 25)
    GetKeyButton.Font = Enum.Font.Gotham
    GetKeyButton.Text = "❓ Получить ключ (Discord)"
    GetKeyButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    GetKeyButton.TextSize = 11
    local GetCorner = Instance.new("UICorner")
    GetCorner.CornerRadius = UDim.new(0, 6)
    GetCorner.Parent = GetKeyButton

    SubmitButton.MouseButton1Click:Connect(function()
        local enteredKey = KeyInput.Text
        local keyType = isValidKey(enteredKey)
        if keyType then
            StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 150)
            StatusLabel.Text = "✅ Ключ принят! Загрузка..."
            if keyType == "hour" then
                saveKey(enteredKey, os.time())
            else
                saveKey(enteredKey)
            end
            task.wait(1)
            ScreenGui:Destroy()
            StartScript()
        else
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            StatusLabel.Text = "❌ Неверный ключ. Попробуй еще раз."
        end
    end)

    GetKeyButton.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/trxhSYeJa")
        StatusLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        StatusLabel.Text = "📋 Ссылка на Discord скопирована!"
    end)
end
