local JosHub = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local RangeLabel = Instance.new("TextLabel")

JosHub.Name = "JosHub_V17_1"
JosHub.Parent = game:GetService("CoreGui")

Main.Name = "Main"
Main.Parent = JosHub
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Position = UDim2.new(0.5, -125, 0.5, -75)
Main.Size = UDim2.new(0, 250, 0, 180)
Main.Active = true
Main.Draggable = true

UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Main

TopBar.Parent = Main
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TopBar.Size = UDim2.new(1, 0, 0, 35)

Title.Parent = TopBar
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "JOS HUB v17.1 - MULTI AURA"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.BackgroundTransparency = 1

ToggleBtn.Parent = Main
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 45)
ToggleBtn.Text = "Activar Aura (v17.1)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = ToggleBtn

StatusLabel.Parent = Main
StatusLabel.Position = UDim2.new(0, 0, 0.7, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Text = "Estado: Standby"
StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.BackgroundTransparency = 1

_G.AuraActiva = false
_G.Rango = 30 -- Rango optimizado

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AuraActiva = not _G.AuraActiva
    
    if _G.AuraActiva then
        ToggleBtn.Text = "Aura: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
        StatusLabel.Text = "Buscando Objetivos..."
        
        task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            local lp = game.Players.LocalPlayer
            
            -- FIX: Verificación profunda para evitar 'nil'
            local combatFolder = rs:FindFirstChild("Combat")
            local remote = combatFolder and combatFolder:FindFirstChild("Melee")

            if not remote then
                StatusLabel.Text = "ERROR: Remote No Encontrado"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                _G.AuraActiva = false
                return
            end

            while _G.AuraActiva do
                -- Verificación de personaje local para evitar errores de magnitud
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = lp.Character.HumanoidRootPart
                    
                    pcall(function()
                        -- Escaneo eficiente
                        for _, obj in pairs(workspace:GetDescendants()) do
                            if obj:IsA("Humanoid") and obj.Parent ~= lp.Character and obj.Health > 0 then
                                local targetChar = obj.Parent
                                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                                
                                if targetHRP then
                                    local dist = (myHRP.Position - targetHRP.Position).Magnitude
                                    if dist <= _G.Rango then
                                        local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                        remote:FireServer(
                                            attacks[math.random(1, #attacks)], 
                                            targetChar, 
                                            targetHRP.CFrame, 
                                            myHRP.CFrame * CFrame.new(0, 0, -1)
                                        )
                                    end
                                end
                            end
                        end
                    end)
                end
                task.wait(0.12) -- Velocidad balanceada para evitar 'Invalidated action'
            end
        end)
    else
        ToggleBtn.Text = "Activar Aura (v17.1)"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StatusLabel.Text = "Estado: Desactivado"
        StatusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    end
end)
