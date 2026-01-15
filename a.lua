--// JOS HUB V17
local JosHub = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local RangeLabel = Instance.new("TextLabel")
local RangeSliderFrame = Instance.new("Frame")
local RangeSliderBtn = Instance.new("TextButton")

JosHub.Name = "JosHub_V17"
JosHub.Parent = (game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))

Main.Name = "Main"
Main.Parent = JosHub
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.Position = UDim2.new(0.5, -125, 0.5, -90)
Main.Size = UDim2.new(0, 250, 0, 230)
Main.Active = true
Main.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

TopBar.Parent = Main
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TopBar.Size = UDim2.new(1, 0, 0, 35)

Title.Parent = TopBar
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "JOS HUB - V17 MULTI"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

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

RangeLabel.Parent = Main
RangeLabel.Position = UDim2.new(0.1, 0, 0.52, 0)
RangeLabel.Size = UDim2.new(0.8, 0, 0, 20)
RangeLabel.Text = "Rango: 25 studs"
RangeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
RangeLabel.Font = Enum.Font.Gotham
RangeLabel.TextSize = 12
RangeLabel.BackgroundTransparency = 1

RangeSliderFrame.Parent = Main
RangeSliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
RangeSliderFrame.Position = UDim2.new(0.1, 0, 0.65, 0)
RangeSliderFrame.Size = UDim2.new(0.8, 0, 0, 6)

RangeSliderBtn.Parent = RangeSliderFrame
RangeSliderBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
RangeSliderBtn.Size = UDim2.new(0.2, 0, 2.5, 0)
RangeSliderBtn.Position = UDim2.new(0.2, 0, -0.75, 0)
RangeSliderBtn.Text = ""

StatusLabel.Parent = Main
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Text = "Estado: Players + NPCs"
StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.BackgroundTransparency = 1

_G.AuraActiva = false
_G.Rango = 25

-- Slider Logic
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

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AuraActiva = not _G.AuraActiva
    
    if _G.AuraActiva then
        ToggleBtn.Text = "Aura: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        
        task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            local p = game.Players.LocalPlayer
            local remote = rs:WaitForChild("Combat", 5):WaitForChild("Melee", 5)

            while _G.AuraActiva do
                pcall(function()
                    -- Buscamos en todo el Workspace (Jugadores y NPCs)
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("Humanoid") and obj.Parent ~= p.Character then
                            local char = obj.Parent
                            local hrp = char:FindFirstChild("HumanoidRootPart")
                            
                            if hrp and obj.Health > 0 then
                                local dist = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                                if dist < _G.Rango then
                                    local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                    remote:FireServer(
                                        attacks[math.random(1, #attacks)], 
                                        char, 
                                        hrp.CFrame, 
                                        p.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-1)
                                    )
                                end
                            end
                        end
                    end
                end)
                task.wait(0.15) -- Un poco mÃ¡s lento para evitar lag por procesar NPCs
            end
        end)
    else
        ToggleBtn.Text = "Activar Kill Aura"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    end
end)
