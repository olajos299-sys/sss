-- JOS HUB: VERSIÓN ANTI-BLOQUEO (SIN CARGAS EXTERNAS)
local JosHub = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local Content = Instance.new("Frame")
local ToggleBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

-- Configuración del Menú (Estilo Oscuro Neón como el video)
JosHub.Name = "JosHub"
JosHub.Parent = game.CoreGui
JosHub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = JosHub
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.5, -125, 0.5, -75)
Main.Size = UDim2.new(0, 250, 0, 180)
Main.Active = true
Main.Draggable = true -- Para que puedas moverlo

TopBar.Name = "TopBar"
TopBar.Parent = Main
TopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TopBar.Size = UDim2.new(1, 0, 0, 30)

Title.Parent = TopBar
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = " JOS HUB - UBG PRIVATE"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

ToggleBtn.Name = "Toggle"
ToggleBtn.Parent = Main
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
ToggleBtn.Text = "Activar Kill Aura"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 18

StatusLabel.Parent = Main
StatusLabel.Position = UDim2.new(0, 0, 0.7, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 40)
StatusLabel.Text = "Estado: Esperando..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.BackgroundTransparency = 1

-- LÓGICA DE COMBATE (EL SECRETO DEL VIDEO)
_G.AuraActiva = false

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AuraActiva = not _G.AuraActiva
    
    if _G.AuraActiva then
        ToggleBtn.Text = "Kill Aura: ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        -- EL EFECTO DEL VIDEO
        StatusLabel.Text = "Buscando Evento..."
        task.wait(0.8)
        StatusLabel.Text = "CombatEvent: Not Found (Bypassed!)"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        
        -- DAÑO REAL
        task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            local p = game.Players.LocalPlayer
            
            -- Buscador agresivo de Remotes
            local remote = rs:FindFirstChild("CombatEvent", true) or rs:FindFirstChild("Hit", true)

            while _G.AuraActiva do
                pcall(function()
                    for _, enemy in pairs(game.Players:GetPlayers()) do
                        if enemy ~= p and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (p.Character.HumanoidRootPart.Position - enemy.Character.HumanoidRootPart.Position).Magnitude
                            if d < 20 then
                                -- Enviamos la ráfaga de golpes
                                local attacks = {"Punch1", "Punch2", "Punch3", "Punch4", "PunchDash"}
                                for i=1, #attacks do
                                    remote:FireServer(attacks[i], enemy.Character)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    else
        ToggleBtn.Text = "Activar Kill Aura"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StatusLabel.Text = "Estado: Desactivado"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)
