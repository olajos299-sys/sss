-- Ultimate Battlegrounds Script Loader
-- Copia este código completo en tu executor

loadstring([[
-- Ultimate Battlegrounds Script
-- Versión: 1.0
-- Funcionalidades completas con GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Variables de configuración
local Config = {
    AutoFarm = false,
    KillAura = false,
    AutoBlock = false,
    SpeedEnabled = false,
    JumpEnabled = false,
    ESPEnabled = false,
    HitboxExpander = false,
    InfiniteStamina = false,
    
    WalkSpeed = 50,
    JumpPower = 100,
    KillAuraRange = 20,
    HitboxSize = 10
}

-- Crear GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")
local MinimizeButton = Instance.new("TextButton")
local ScrollFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")

ScreenGui.Name = "UltimateBattlegroundsGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "Ultimate Battlegrounds Script"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.TextSize = 18

CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = MainFrame
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(1, -70, 0, 5)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 20

ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Parent = MainFrame
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Position = UDim2.new(0, 10, 0, 50)
ScrollFrame.Size = UDim2.new(1, -20, 1, -60)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 6

UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local function CreateToggle(name, callback)
    local ToggleFrame = Instance.new("Frame")
    local ToggleButton = Instance.new("TextButton")
    local ToggleLabel = Instance.new("TextLabel")
    
    ToggleFrame.Name = name .. "Frame"
    ToggleFrame.Parent = ScrollFrame
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Size = UDim2.new(1, -10, 0, 40)
    
    ToggleLabel.Name = "Label"
    ToggleLabel.Parent = ToggleFrame
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.Text = name
    ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleLabel.TextSize = 14
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    ToggleButton.Name = "Button"
    ToggleButton.Parent = ToggleFrame
    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Position = UDim2.new(0.75, 0, 0.2, 0)
    ToggleButton.Size = UDim2.new(0.2, 0, 0.6, 0)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Text = "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 12
    
    local toggled = false
    ToggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            ToggleButton.Text = "ON"
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            ToggleButton.Text = "OFF"
        end
        callback(toggled)
    end)
end

CreateToggle("Auto Farm", function(enabled) Config.AutoFarm = enabled end)
CreateToggle("Kill Aura", function(enabled) Config.KillAura = enabled end)
CreateToggle("Auto Block", function(enabled) Config.AutoBlock = enabled end)
CreateToggle("Speed Boost", function(enabled)
    Config.SpeedEnabled = enabled
    Humanoid.WalkSpeed = enabled and Config.WalkSpeed or 16
end)
CreateToggle("Jump Power", function(enabled)
    Config.JumpEnabled = enabled
    Humanoid.JumpPower = enabled and Config.JumpPower or 50
end)
CreateToggle("ESP (Players)", function(enabled) Config.ESPEnabled = enabled end)
CreateToggle("Hitbox Expander", function(enabled) Config.HitboxExpander = enabled end)
CreateToggle("Infinite Stamina", function(enabled) Config.InfiniteStamina = enabled end)

ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)

CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    ScrollFrame.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 400, 0, 40) or UDim2.new(0, 400, 0, 500)
end)

local function GetClosestEnemy()
    local closestDistance = math.huge
    local closestEnemy = nil
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = player.Character:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHumanoid and enemyHumanoid.Health > 0 then
                local distance = (HumanoidRootPart.Position - enemyHRP.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestEnemy = player
                end
            end
        end
    end
    
    return closestEnemy, closestDistance
end

local function Attack()
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Combat"):FireServer("M1")
    end)
end

RunService.Heartbeat:Connect(function()
    if Config.KillAura then
        local enemy, distance = GetClosestEnemy()
        if enemy and distance <= Config.KillAuraRange then
            Attack()
        end
    end
    
    if Config.AutoFarm then
        local enemy = GetClosestEnemy()
        if enemy and enemy.Character then
            local enemyHRP = enemy.Character:FindFirstChild("HumanoidRootPart")
            if enemyHRP then
                HumanoidRootPart.CFrame = CFrame.new(enemyHRP.Position + Vector3.new(0, 0, 5))
                task.wait(0.1)
                Attack()
            end
        end
    end
    
    if Config.SpeedEnabled then
        Humanoid.WalkSpeed = Config.WalkSpeed
    end
    
    if Config.JumpEnabled then
        Humanoid.JumpPower = Config.JumpPower
    end
    
    if Config.InfiniteStamina then
        local stamina = LocalPlayer:FindFirstChild("Stamina")
        if stamina and stamina:IsA("NumberValue") then
            stamina.Value = 100
        end
    end
    
    if Config.HitboxExpander then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = 0.8
                    hrp.CanCollide = false
                end
            end
        end
    end
    
    if Config.AutoBlock then
        local enemy, distance = GetClosestEnemy()
        if enemy and distance <= 15 then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Combat"):FireServer("Block", true)
            end)
        end
    end
end)

local function CreateESP(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local BillboardGui = Instance.new("BillboardGui")
        local TextLabel = Instance.new("TextLabel")
        
        BillboardGui.Name = "ESP"
        BillboardGui.Parent = player.Character.HumanoidRootPart
        BillboardGui.AlwaysOnTop = true
        BillboardGui.Size = UDim2.new(0, 100, 0, 50)
        BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
        
        TextLabel.Parent = BillboardGui
        TextLabel.BackgroundTransparency = 1
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.Text = player.Name
        TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        TextLabel.TextSize = 14
        TextLabel.TextStrokeTransparency = 0
    end
end

RunService.Heartbeat:Connect(function()
    if Config.ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not player.Character.HumanoidRootPart:FindFirstChild("ESP") then
                    CreateESP(player)
                end
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local esp = player.Character.HumanoidRootPart:FindFirstChild("ESP")
                if esp then esp:Destroy() end
            end
        end
    end
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Ultimate Battlegrounds";
    Text = "Script cargado exitosamente!";
    Duration = 5;
})

print("Ultimate Battlegrounds Script cargado!")
]])()
