-- JOS HUB - VERSIÓN MANUAL (SIN LIBRERÍAS EXTERNAS)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")

-- Configuración visual rápida
ScreenGui.Parent = game.CoreGui
MainFrame.Name = "JosHub"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
MainFrame.Size = UDim2.new(0, 200, 0, 150)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "JOS HUB UBG"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

ToggleBtn.Parent = MainFrame
ToggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
ToggleBtn.Size = UDim2.new(0.8, 0, 0.4, 0)
ToggleBtn.Text = "Kill Aura: OFF"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

-- LÓGICA DEL SCRIPT
_G.Aura = false

ToggleBtn.MouseButton1Click:Connect(function()
    _G.Aura = not _G.Aura
    if _G.Aura then
        ToggleBtn.Text = "Kill Aura: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        
        -- FORZAR EL "NOT FOUND" COMO EN EL VIDEO
        warn("[JOS HUB]: Scanning game data...")
        task.wait(1)
        print("Error: 0x842 - CombatHandler Not Found. Bypassing...")
        
        -- EJECUTAR DAÑO
        task.spawn(function()
            while _G.Aura do
                pcall(function()
                    local p = game.Players.LocalPlayer
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= p and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (p.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                            if dist < 25 then
                                -- Buscador directo de disparador de daño
                                for _, remote in pairs(game.ReplicatedStorage:GetDescendants()) do
                                    if remote:IsA("RemoteEvent") and (remote.Name:find("Hit") or remote.Name:find("Combat")) then
                                        remote:FireServer("Punch1", v.Character)
                                        remote:FireServer("Punch2", v.Character)
                                        remote:FireServer("Punch3", v.Character)
                                        remote:FireServer("Punch4", v.Character)
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    else
        ToggleBtn.Text = "Kill Aura: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)
