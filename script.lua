-- Blox Fruits AutoFarm by Gta90988
if getgenv().BF_SCRIPT then getgenv().BF_SCRIPT:Destroy() end

local Players = game:GetService("Players")
local p = Players.LocalPlayer
local sg = Instance.new("ScreenGui")
sg.Name = "BF_Script"
sg.ResetOnSpawn = false
sg.Parent = p:WaitForChild("PlayerGui")
getgenv().BF_SCRIPT = sg

-- Кнопка вкл/выкл
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0, 20, 0, 200)
btn.Text = "AutoFarm: OFF"
btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 18
btn.Font = Enum.Font.GothamBold
btn.BorderSizePixel = 0

-- Кнопка телепорта
local tpBtn = Instance.new("TextButton", sg)
tpBtn.Size = UDim2.new(0, 200, 0, 40)
tpBtn.Position = UDim2.new(0, 20, 0, 260)
tpBtn.Text = "ТП к ближайшему мобу"
tpBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.TextSize = 16
tpBtn.Font = Enum.Font.GothamBold
tpBtn.BorderSizePixel = 0

local on = false

-- Поиск ближайшего моба
local function getNearestMob()
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local nearest, dist = nil, math.huge
    for _, m in pairs(workspace:GetChildren()) do
        if m ~= char
            and m:FindFirstChild("Humanoid")
            and m:FindFirstChild("HumanoidRootPart")
            and m.Humanoid.Health > 0
            and not Players:GetPlayerFromCharacter(m)
        then
            local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
            if d < dist and d < 500 then
                nearest, dist = m, d
            end
        end
    end
    return nearest
end

-- Атака
local function attackMob(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return end
    local char = p.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
end

-- Кнопки
btn.MouseButton1Click:Connect(function()
    on = not on
    btn.Text = "AutoFarm: " .. (on and "ON" or "OFF")
    btn.BackgroundColor3 = on and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

tpBtn.MouseButton1Click:Connect(function()
    local mob = getNearestMob()
    if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    end
end)

-- Главный цикл
task.spawn(function()
    while task.wait(0.15) do
        if on then
            local mob = getNearestMob()
            if mob and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                attackMob(mob)
            end
        end
    end
end)

print("[BF Script] Загружен успешно!")
