--// JOS HUB V16 - NATIVE UI (BYPASS 404)
local JosHub = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local Content = Instance.new("Frame")
local ToggleBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local RangeLabel = Instance.new("TextLabel")
local RangeSliderFrame = Instance.new("Frame")
local RangeSliderBtn = Instance.new("TextButton")

-- Configuración Base
JosHub.Name = "JosHub_V16"
 JosHub.Parent = (game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
JosHub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Marco Principal
Main.Name = "Main"
Main.Parent = JosHub
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -125, 0.5, -90)
Main.Size = UDim2.new(0, 250, 0, 220)
Main.Active = true
Main.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

-- Barra Superior
TopBar.Name = "TopBar"
TopBar.Parent = Main
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TopBar.Size = UDim2.new(1, 0, 0, 35)

Title.Parent = TopBar
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "JOS HUB - V16 PRIVATE"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

-- BOTÓN TOGGLE (Kill Aura)
ToggleBtn.Name = "Toggle"
ToggleBtn.Parent = Main
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.25, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 45)
ToggleBtn.Text = "Activar Kill Aura"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = ToggleBtn

-- SLIDER DE RANGO (Manual)
RangeLabel.Parent = Main
RangeLabel.Position = UDim2.new(0.1, 0, 0.52, 0)
RangeLabel.Size = UDim2.new(0.8, 0, 0, 20)
RangeLabel.Text = "Rango: 25 studs"
RangeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
RangeLabel.Font = Enum.Font.Gotham
RangeLabel.TextSize = 12
RangeLabel.BackgroundTransparency = 1

RangeSliderFrame.Name = "SliderBG"
RangeSliderFrame.Parent = Main
RangeSliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
RangeSliderFrame.Position = UDim2.new(0.1, 0, 0.65, 0)
RangeSliderFrame.Size = UDim2.new(0.8, 0, 0, 6)

RangeSliderBtn.Name = "SliderHead"
RangeSliderBtn.Parent = RangeSliderFrame
RangeSliderBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
RangeSliderBtn.Size = UDim2.new(0.2, 0, 2.5, 0)
RangeSliderBtn.Position = UDim2.new(0.2, 0, -0.75, 0)
RangeSliderBtn.Text = ""

-- ESTADO
StatusLabel.Parent = Main
StatusLabel.Position = UDim2.new(0, 0, 0.82, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Text = "Estado: Listo"
StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.BackgroundTransparency = 1

--// LÓGICA DE COMBATE ACTUALIZADA
_G.AuraActiva = false
_G.Rango = 25

-- Función de Slider
RangeSliderBtn.MouseButton1Down:Connect(function()
    local moveConn
    moveConn = game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp((input.Position.X - RangeSliderFrame.AbsolutePosition.X) / RangeSliderFrame.AbsoluteSize.X, 0, 1)
            RangeSliderBtn.Position = UDim2.new(relativeX, -RangeSliderBtn.AbsoluteSize.X/2, -0.75, 0)
            _G.Rango = math.floor(relativeX * 100)
            RangeLabel.Text = "Rango: ".._G.Rango.." studs"
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            moveConn:Disconnect()
        end
    end)
end)

-- Función de Kill Aura
ToggleBtn.MouseButton1Click:Connect(function()
    _G.AuraActiva = not _G.AuraActiva
    
    if _G.AuraActiva then
        ToggleBtn.Text = "Aura: ACTIVADA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        StatusLabel.Text = "Buscando Combat.Melee..."
        
        task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            local p = game.Players.LocalPlayer
            
            -- Ruta exacta que encontraste en Dex
            local remote = rs:WaitForChild("Combat", 5):WaitForChild("Melee", 5)

            if remote then
                StatusLabel.Text = "Conectado a Combat.Melee"
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            end

            while _G.AuraActiva do
                pcall(function()
                    for _, enemy in pairs(game.Players:GetPlayers()) do
                        if enemy ~= p and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = enemy.Character.HumanoidRootPart
                            local dist = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                            
                            if dist < _G.Rango and enemy.Character.Humanoid.Health > 0 then
                                local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                remote:FireServer(
                                    attacks[math.random(1, #attacks)], 
                                    enemy.Character, 
                                    hrp.CFrame, 
                                    p.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-1)
                                )
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    else
        ToggleBtn.Text = "Activar Kill Aura"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        StatusLabel.Text = "Estado: Desactivado"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)
